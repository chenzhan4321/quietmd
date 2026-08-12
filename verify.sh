#!/bin/sh
# quietmd 自检 —— 你可以自己跑这条，不用信我的话。
#   zsh verify.sh
# 它会渲染一份「折磨测试」文档，用无头 Chrome 真的跑一遍 MathJax，
# 然后核对：哪些公式渲染成功、哪些失败、$ 有没有被误认、代码块有没有被动过。
# 期望结果：39 个公式里恰好 1 个失败（那条是故意写错的），其余检查全 PASS。

set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
# 依次找一个 Chromium 系浏览器；CI 上是 Linux，本机通常是 macOS
CHROME=""
for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
         "/Applications/Google Chrome Beta.app/Contents/MacOS/Google Chrome Beta" \
         "/Applications/Chromium.app/Contents/MacOS/Chromium" \
         "$(command -v google-chrome 2>/dev/null)" \
         "$(command -v chromium 2>/dev/null)" \
         "$(command -v chromium-browser 2>/dev/null)"; do
    [ -n "$c" ] && [ -x "$c" ] && CHROME="$c" && break
done
[ -n "$CHROME" ] || { echo "找不到 Chrome/Chromium" >&2; exit 2; }

cat > "$WORK/t.md" <<'MD'
# 自检

1 下标：$a_1, a_2, \ldots, a_n$ 与 $S_n = \sum_{i=1}^n a_i$

2 换行：
$$
\begin{aligned}
f(x) &= (x+1)^2 \\
     &= x^2 + 2x + 1
\end{aligned}
$$

3 裸环境与编号：
\begin{align}
\nabla \times \mathbf{E} &= -\frac{\partial \mathbf{B}}{\partial t} \label{eq:a} \\
\nabla \cdot \mathbf{B} &= 0 \label{eq:b}
\end{align}

4 交叉引用：见 \eqref{eq:a} 和 \eqref{eq:b}。

5 宏：$$\newcommand{\Rr}{\mathbb{R}}$$ 于是 $x \in \Rr^n$。

6 货币：花了 $200，又花 $1500，共 $1700。转义 \$99。

7 代码：`$PATH` 和 `\begin{align}`

```bash
echo $HOME; awk '{s+=$2}' f.txt
```

8 故意写错（必须报错）：$\frac{1}{$
MD

echo "→ 渲染 …"
uv run --quiet --script "$DIR/quietmd.py" "$WORK/t.md" --no-open -o "$WORK/t.html" >/dev/null

echo "→ 无头 Chrome 实跑 MathJax …"
"$CHROME" --headless=new --disable-gpu --no-sandbox --virtual-time-budget=30000 \
  --dump-dom "file://$WORK/t.html" > "$WORK/dom.html" 2>/dev/null

python3 - "$WORK" <<'PY'
import re, sys, pathlib
w = pathlib.Path(sys.argv[1])
src  = (w/'t.html').read_text(encoding='utf-8')
dom  = (w/'dom.html').read_text(encoding='utf-8')
fails = []
def chk(name, cond, note=""):
    print(("  \033[32mPASS\033[0m  " if cond else "  \033[31mFAIL\033[0m  ") + name + (f"   {note}" if not cond else ""))
    if not cond: fails.append(name)

body = re.search(r'<body[^>]*>', dom).group(0)
total  = int(re.search(r'data-math-total="(\d+)"',  body).group(1))
failed = int(re.search(r'data-math-failed="(\d+)"', body).group(1))
print(f"\n  公式总数 {total}，渲染失败 {failed}\n")

chk("MathJax 跑完了",                     'data-math-ready="1"' in body)
chk("恰好 1 个公式失败（那条是故意写错的）", failed == 1, f"实际 {failed}")
bad = re.findall(r'class="mjx-\w+ mjx-failed" data-tex="([^"]*)"', dom)
chk("失败的正是 \\frac{1}{ 那条",          bad == ['\\frac{1}{'], f"实际 {bad}")
chk("下标 a_1 没被 Markdown 吃成斜体",     r'a_1, a_2, \ldots, a_n' in src)
# 每条公式的源码在 HTML 里出现两次：data-tex 属性一份（供双击复制），公式槽一份
chk("\\\\ 换行没被吃掉",                   src.count(r'&amp;= (x+1)^2 \\') == 2
                                           and src.count(r'&amp;= x^2 + 2x + 1') == 2)
chk("裸 \\begin{align} 被识别为块级公式",  r'<span class="mjx-block" data-tex="\begin{align}' in src)
chk("\\label 生成了公式编号锚点",          len(re.findall(r'id="mjx-eqn[^"]*"', dom)) == 2)
chk("\\eqref 渲染成可点击的引用",          dom.count('href="#mjx-eqn%3Aeq%3Aa"') >= 1)
chk("\\newcommand 定义的宏在后文可用",     r'x \in \Rr^n' in src and '\\Rr' not in [b for b in bad])
money = src[src.find('6 货币'):src.find('6 货币')+160]
chk("$200 / $1500 / $1700 没被当成公式",   'mjx' not in money and '$200' in money, repr(money[:80]))
chk("转义的 \\$99 显示为 $99",             '$99' in src)
pre = "".join(re.findall(r'<pre[^>]*>[\s\S]*?</pre>', src))
chk("代码块里的 $HOME / $2 原样保留",      '$HOME' in pre and '$2' in pre and 'mjx-' not in pre)
chk("行内代码 `\\begin{align}` 没被渲染",  r'<code>\begin{align}</code>' in src)
chk("没有占位符残留",                      '' not in src and '' not in src)
chk("MathJax 已内嵌（离线可用）",          len(src) > 2_000_000 and 'MathJax' in src)

print()
if fails:
    print(f"\033[31m{len(fails)} 项未通过\033[0m"); sys.exit(1)
print("\033[32m全部通过\033[0m"); sys.exit(0)
PY
rc=$?
rm -rf "$WORK"
exit $rc
