#!/bin/sh
# quietmd 安装脚本。
#
#   ./install.sh              装命令
#   ./install.sh --macos-app  顺便装 Finder 双击关联（仅 macOS）
#
# 装的东西：
#   ~/.local/share/quietmd/quietmd.py   程序本体
#   ~/.local/bin/quietmd                命令
# MathJax 不在这里下载 —— 第一次运行 quietmd 时它自己会抓，并且带镜像回退。

set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
LIB="$HOME/.local/share/quietmd"
BIN="$HOME/.local/bin"

# 找 uv 的方式必须和下面写进 wrapper 的那段一致。只用 command -v 是不够的：
# 非交互式 shell（ssh host './install.sh'）的 PATH 里没有 /opt/homebrew/bin，
# 明明装了 uv 也会被判定成没装。
UV=""
for c in "$HOME/.local/bin/uv" /opt/homebrew/bin/uv /usr/local/bin/uv "$HOME/.cargo/bin/uv"; do
    [ -x "$c" ] && UV="$c" && break
done
[ -z "$UV" ] && UV="$(command -v uv 2>/dev/null || true)"
if [ -z "$UV" ]; then
    echo "需要 uv（用来管理 Python 依赖）。装法：" >&2
    echo "  curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
    exit 1
fi
echo "用的 uv：$UV"

mkdir -p "$LIB" "$BIN"
cp "$SRC/quietmd.py" "$LIB/quietmd.py"
cp "$SRC/verify.sh"  "$LIB/verify.sh"
cp "$SRC/tests/math_torture.md" "$LIB/math_torture.md"

cat > "$BIN/quietmd" <<'EOF'
#!/bin/sh
# 从 Finder 启动时 PATH 只有 /usr/bin:/bin:/usr/sbin:/sbin，找不到 uv，
# 所以这里按候选路径显式找，不能依赖 PATH。
for c in "$HOME/.local/bin/uv" /opt/homebrew/bin/uv /usr/local/bin/uv "$HOME/.cargo/bin/uv"; do
    [ -x "$c" ] && UV="$c" && break
done
[ -z "$UV" ] && UV="$(command -v uv)"
[ -z "$UV" ] && { echo "找不到 uv：curl -LsSf https://astral.sh/uv/install.sh | sh" >&2; exit 1; }
exec "$UV" run --quiet --script "$HOME/.local/share/quietmd/quietmd.py" "$@"
EOF
chmod +x "$BIN/quietmd"

echo "已安装：$BIN/quietmd"
case ":$PATH:" in
    *":$BIN:"*) ;;
    *) echo "提醒：$BIN 不在 PATH 里，把它加进 shell 配置。" >&2 ;;
esac

# ---- macOS：Finder 双击 .md 用 quietmd 打开 ----------------------------
if [ "$1" = "--macos-app" ]; then
    [ "$(uname)" = "Darwin" ] || { echo "--macos-app 只适用于 macOS" >&2; exit 1; }
    APP="$HOME/Applications/quietmd.app"
    rm -rf "$APP"
    # 必须是 AppleScript 应用：只有它能接收 Finder 的「打开文档」事件
    osacompile -o "$APP" "$SRC/macos/app.applescript"

    PB=/usr/libexec/PlistBuddy
    INFO="$APP/Contents/Info.plist"
    $PB -c "Add :CFBundleIdentifier string top.quietmd.app" "$INFO" 2>/dev/null || \
        $PB -c "Set :CFBundleIdentifier top.quietmd.app" "$INFO"
    $PB -c "Add :CFBundleName string quietmd" "$INFO" 2>/dev/null || true
    # osacompile 默认声称能打开「*」，会污染其它文件类型的「打开方式」列表，删掉
    $PB -c "Delete :CFBundleDocumentTypes" "$INFO" 2>/dev/null || true
    $PB -c "Add :CFBundleDocumentTypes array" "$INFO"
    $PB -c "Add :CFBundleDocumentTypes:0 dict" "$INFO"
    $PB -c "Add :CFBundleDocumentTypes:0:CFBundleTypeName string Markdown Document" "$INFO"
    $PB -c "Add :CFBundleDocumentTypes:0:CFBundleTypeRole string Viewer" "$INFO"
    $PB -c "Add :CFBundleDocumentTypes:0:LSHandlerRank string Alternate" "$INFO"
    $PB -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes array" "$INFO"
    $PB -c "Add :CFBundleDocumentTypes:0:LSItemContentTypes:0 string net.daringfireball.markdown" "$INFO"
    $PB -c "Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions array" "$INFO"
    i=0
    for e in md markdown mdown mkd mkdn mdwn mdtxt mdtext; do
        $PB -c "Add :CFBundleDocumentTypes:0:CFBundleTypeExtensions:$i string $e" "$INFO"
        i=$((i + 1))
    done

    if [ -f "$SRC/docs/icon.png" ] && command -v iconutil >/dev/null 2>&1; then
        ICONSET="$(mktemp -d)/quietmd.iconset"; mkdir -p "$ICONSET"
        for s in 16 32 128 256 512; do
            sips -z $s $s "$SRC/docs/icon.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null 2>&1
            d=$((s * 2))
            sips -z $d $d "$SRC/docs/icon.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null 2>&1
        done
        iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/droplet.icns" 2>/dev/null || true
    fi

    codesign --force --sign - "$APP" 2>/dev/null || true
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"
    echo "已安装：$APP"

    if command -v duti >/dev/null 2>&1; then
        for u in net.daringfireball.markdown; do duti -s top.quietmd.app "$u" all; done
        for e in md markdown mdown mkd mkdn mdwn; do duti -s top.quietmd.app "$e" all; done
        echo "已设为 .md 的默认打开方式（改回去：duti -s <别的 bundle id> net.daringfireball.markdown all）"
        echo "注意 duti -x md 的查询结果有缓存，可能仍显示旧值；"
        echo "真正的检验是双击一个 .md，看 ~/.cache/quietmd/ 里有没有出现对应 HTML。"
    else
        echo "没装 duti，无法自动设默认打开方式。"
        echo "手动：Finder 里右键 .md →「显示简介」→「打开方式」选 quietmd →「全部更改」"
    fi
fi
