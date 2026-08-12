#!/bin/sh
# 卸载 quietmd。默认只删它自己装的东西，不碰你渲染出来的 HTML。
#
#   ./uninstall.sh            删命令、程序本体、macOS 应用
#   ./uninstall.sh --cache    连 ~/.cache/quietmd 一起删

set -e

BIN="$HOME/.local/bin/quietmd"
LIB="$HOME/.local/share/quietmd"
APP="$HOME/Applications/quietmd.app"

for target in "$BIN" "$LIB" "$APP"; do
    if [ -e "$target" ]; then
        rm -rf "$target"
        echo "已删除 $target"
    fi
done

# 旧版本叫 mdview，如果那个软链指向的是 quietmd，一并收拾掉
if [ -L "$HOME/.local/bin/mdview" ]; then
    case "$(readlink "$HOME/.local/bin/mdview")" in
        *quietmd*) rm -f "$HOME/.local/bin/mdview"; echo "已删除 $HOME/.local/bin/mdview（指向 quietmd 的软链）";;
    esac
fi

if [ "$1" = "--cache" ] && [ -d "$HOME/.cache/quietmd" ]; then
    rm -rf "$HOME/.cache/quietmd"
    echo "已删除 $HOME/.cache/quietmd"
fi

if command -v duti >/dev/null 2>&1; then
    cur="$(duti -x md 2>/dev/null | tail -1 || true)"
    case "$cur" in
        top.quietmd.app)
            echo
            echo "注意：.md 的默认打开方式仍指向刚被删掉的 quietmd。"
            echo "换回别的应用，例如 Typora："
            echo "  duti -s abnerworks.Typora net.daringfireball.markdown all"
            ;;
    esac
fi

echo
echo "卸载完成。渲染出来的 .html 文件都还在原处，没有动。"
