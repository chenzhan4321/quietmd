<h1 align="center">
  <img src="docs/icon.png" width="88" alt=""><br>
  quietmd
</h1>

<p align="center">
  安静地读带公式的 Markdown。<br>
  一个自包含的 HTML 文件，完全离线 ——<br>
  哪条公式没排出来，它会告诉你。
</p>

<p align="center">
  <a href="https://github.com/chenzhan4321/quietmd/actions/workflows/verify.yml"><img src="https://github.com/chenzhan4321/quietmd/actions/workflows/verify.yml/badge.svg" alt="verify"></a>
  <img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT">
  <a href="README.md">English</a>
</p>

<p align="center"><img src="docs/style-paper.png" width="820" alt=""></p>

```console
$ quietmd paper.md            # 渲染并打开；HTML 就写在源文件旁边
$ quietmd paper.md -w         # 实时预览，存盘即刷新
$ quietmd paper.md --check    # 列出没排出来的公式；全部正常则退出码 0
```

## 为什么

我写的论文里数学很多，而 Markdown 编辑器总把它弄坏。Typora 和 iA Writer 上反复遇到同样的事：
下标不见了、多行公式挤成一行、整块 `align` 显示成原始文本。

这是个顺序问题，多数编辑器都一样：**先跑 Markdown 解析器，再把结果喂给数学渲染器**。
等 KaTeX 或 MathJax 见到你的公式时，Markdown 已经先动过手了 ——
它把 `a_i b_i` 里的 `_` 当成了斜体标记，又吃掉了 `\\` 里的一个反斜杠。

quietmd 把顺序反过来：**在 Markdown 跑之前先把每条公式从原文里取出来**，留一个占位符，
解析器因此碰不到任何一个 LaTeX 字符；渲染完再把公式原样放回去。`$` 也完全不参与 MathJax 的扫描，
所以 `花了 $200，又花 $1500` 不会变成公式。

## 哪条公式没排出来，它会告诉你

这是我真正在意的部分。渲染器出错时是不声不响的：MathJax 可能抛个异常就跳过那一段，
页面上留下的原始 LaTeX 看起来跟你本来就想写的文字一模一样，你会直接翻过去。

所以 quietmd 不问渲染器成没成功 —— 渲染完之后它**自己逐条检查每个公式**：

<p align="center"><img src="docs/errors.png" width="740" alt=""></p>

红框：这条根本没解析成，通常是括号没配对。橙色下划线：有一个命令不认识，但其余部分排出来了，
仍然读得懂。两种情况角落都会出现提示，点它会逐条带你过去。

投稿前想一次扫完全稿：

```console
$ quietmd paper.md --check
paper.md：2270 处公式，0 处排不出来，0 处含不认识的命令
  全部正常。
```

只有全部渲染成功退出码才是 0，可以直接进脚本。
它还会交叉比对稿件本身，这部分完全不需要浏览器：

```console
$ quietmd paper.md --check
  [悬空引用] \eqref{eq:missing} → 找不到对应的 \label
  [重复的 label] \label{eq:dup} 出现了 2 次，编号会错
  [未使用的宏] \NeverUsed 定义了但从未使用
```

指向不存在的 label 的 `\eqref` 会渲染成 `???`，很容易翻过去；同一个 label 写两遍，
从那里开始编号就全错了，而且没有任何提示。


## 找东西

`⌘F` 找不到公式 —— 公式是 SVG，一本两千多条公式的书里，「那个带 sigma_i 的式子在哪」
根本无从找起。按 `/` 或 `⌘K`：

<p align="center"><img src="docs/find.png" width="700" alt=""></p>

它同时搜正文、标题**和每条公式的 LaTeX 源码**。输入数字就跳到该编号的公式 ——
输入 `2` 能找到第 (2) 式，哪怕它在一个带好几个编号的 `align` 块里。
`↑`/`↓` 选，`Enter` 跳过去。

## 一个目录当一本书

一串按序号排的文件往往*就是*一份东西 —— 教材的各章、论文的各节。直接把目录给它：

```console
$ quietmd drafts/
drafts/：按文件名接了 8 份
  chapter_01_the_symptom.md
  ...
```

按文件名排序拼接（`chapter_01…08` 这种命名本来就是为排序取的），侧栏目录直接是全书结构。
以 `_` 或 `.` 开头的文件跳过 —— 那些通常是写给作者自己的旁注，不是正文。
别的用 `--exclude 'full_*.md'` 排除；文件清单每次都会打印出来，因为目录里要是混着
一份已经合并好的稿子，内容就会被算两遍。

## 直接出 PDF

```console
$ quietmd drafts/ --pdf -s book
drafts.pdf  （73 页，4.2 MB，book 版式）
```

不用装 LaTeX，也不用点打印菜单。选的风格*就是*版式，同一份源文件可以出成 LaTeX 模样的
article、一本书、或者双倍行距的校对稿。工具栏、侧栏、角落的提示都不会印上去，标题不会被
甩在页脚，纸面一律白底 —— 风格的底色是屏幕上的事。

## 排版风格

八种，全部内嵌在页面里 —— 下拉框选，或按 `s` 循环。每一种都照着真实存在的东西做，不是自己编的。

| | 出处 |
|---|---|
| `paper` | 暖白纸、衬线、侧边目录（默认） |
| `latex` | LaTeX `article` —— 两端对齐、首行缩进、标题居中 |
| `book` | 传统书籍排版，米黄纸 |
| `tufte` | [tufte-css](https://edwardtufte.github.io/tufte-css/) |
| `medium` | Medium 长文页 |
| `github` | GitHub README |
| `swiss` | 国际主义平面设计 |
| `manuscript` | 打字稿、双倍行距，适合校对 |

<p align="center">
  <img src="docs/style-latex.png" width="260" alt="">
  <img src="docs/style-tufte.png" width="260" alt="">
  <img src="docs/style-github.png" width="260" alt="">
</p>

工具栏显示的是真实的排版参数 —— 一行能排多少个字、正文多大 —— 而不是「窄/适中/宽」。
界面默认英文，有一个 `中文` 按钮。

## 安装

需要 [uv](https://docs.astral.sh/uv/)。Chromium 系浏览器只有 `--check` 用得到，平时看文档任何浏览器都行。

```console
$ git clone https://github.com/chenzhan4321/quietmd.git
$ cd quietmd && ./install.sh
```

macOS 上加 `./install.sh --macos-app`，双击 `.md` 就用它打开。

想卸载：`./uninstall.sh`（加 `--cache` 连渲染缓存一起删）。

MathJax（2.2 MB）没放进版本库 —— 第一次运行时下载一次，之后全程不联网。

## 自己验证

上面这些不用信我：

```console
$ sh verify.sh
```

它渲染一份折磨测试文档，用无头 Chrome 真跑一遍 MathJax，核对 15 件事 ——
下标有没有被解析器吃掉、`\\` 换行、裸 `\begin{align}`、`\label`/`\eqref` 编号与交叉引用、
`\newcommand` 跨公式生效、货币金额**没有**变成公式、代码块原封不动。
预期：15 项通过，并且**恰好一条公式失败** —— 测试文档里故意写坏了一条。
哪天这个失败消失了，说明坏掉的是错误检测本身。

<details>
<summary>更多细节</summary>

**行内 `$…$`** 沿用 pandoc 的保守规则：开定界符后不能是空白、闭定界符前不能是空白、
闭定界符后不能紧跟数字、内容不跨空行。不满足就当普通美元符号。扫描跳过代码块，
所以 `echo $PATH` 不会被当成公式。

**数学** —— `$…$` `$$…$$` `\(…\)` `\[…\]`、amsmath 全套环境、`\newcommand` 跨公式生效、
`\label`+`\eqref` 自动编号与可点击交叉引用，以及 MathJax 的全部扩展包。

**Markdown** —— GFM 表格、删除线、任务列表、脚注、定义列表、YAML front matter、
Pygments 代码高亮、自动链接。

**阅读** —— 侧边目录跟随滚动、阅读进度条、明暗跟随系统、超长公式横向滚动、
双击公式复制 LaTeX、打印样式、刷新后回到原位置。键位：`j`/`k` 滚动、`g`/`G` 首尾、
`t` 明暗、`s` 风格、`h` 目录、`l` 语言、`[` `]` 宽度。

**产物** —— 就放在源文件旁边（`paper.md` → `paper.html`）。如果同名文件已存在且不是
quietmd 写的，会改写成 `paper.quietmd.html`，不动你自己的文件。图片内嵌，所以真的是
一个可以直接发给别人的文件。

**关于别的工具** —— pandoc 的数学是对的：它的 Markdown reader 原生就懂 math，不是后处理，
所以不会犯上面那些错。VS Code 的 Markdown Preview Enhanced、Mathpix 的 markdown-it、
Quarto 也一样。差别有两处：pandoc 默认没开 `tags:'ams'`，`\label`/`\eqref` 交叉引用不工作；
以及它们都不会告诉你哪条公式没渲染出来。

</details>

## 许可

MIT。MathJax 由程序运行时下载，不属于本仓库
（[Apache-2.0](https://github.com/mathjax/MathJax/blob/master/LICENSE)）。
`tufte` 风格参照 [tufte-css](https://github.com/edwardtufte/tufte-css)（MIT）。
