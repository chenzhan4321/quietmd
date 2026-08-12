<h1 align="center">
  <img src="docs/icon.png" width="96" alt=""><br>
  quietmd
</h1>

<p align="center">
  安静地读带公式的 Markdown。<br>
  渲染成一个自包含的 HTML 文件，完全离线，<br>
  <b>而且会告诉你哪条公式没排出来</b>。
</p>

<p align="center"><a href="README.md">English</a></p>

<p align="center"><img src="docs/style-paper.png" width="820" alt="quietmd 纸张风格"></p>

```console
$ quietmd paper.md              # 渲染并打开；HTML 就写在源文件旁边（paper.md → paper.html）
$ quietmd paper.md -w           # 实时预览，存盘即刷新
$ quietmd paper.md -o out.html  # 只出文件 —— 可以直接发给别人，离线能看
$ quietmd paper.md --check      # 列出排不出来的公式；全部正常则退出码 0
```

---

## 为什么要写这个

Markdown 编辑器把公式弄坏的方式都一样：**先跑 Markdown 解析器，再把结果喂给数学渲染器**。
等 KaTeX 或 MathJax 见到你的公式时，Markdown 已经先动过手了。

| 你写的 | Markdown 解析器干的事 | 你看到的 |
|---|---|---|
| `$a_i b_i$` | 把 `_i b_` 当成斜体标记 | 下标没了，中间一段变斜体 |
| `\\` 换行 | 当成转义反斜杠吞掉一个 | 多行公式挤成一行 |
| `\begin{align}` | 不认识，当普通段落 | 整块显示成原始文本 |
| `\eqref{eq:1}` | 原样输出 | MathJax 3 不扫描定界符外的引用，不生效 |

quietmd 反过来做：**先上锁，再渲染，最后放回**。

1. 线性扫描原文，把每一段数学（`$…$`、`$$…$$`、`\(…\)`、`\[…\]`、裸 `\begin{align}` 等）
   抠出来换成 Unicode 私用区占位符。扫描时**跳过代码块和行内代码**，
   所以 `echo $PATH` 里的 `$` 永远不会被当成公式。
2. 把只剩占位符的文本交给 Markdown 解析器。它碰不到任何一个 LaTeX 字符。
3. 渲染完把公式原样放回，交给 MathJax 3（SVG 输出，不依赖外部字体）。
   `$` 完全不参与 MathJax 自己的扫描 —— 所以 `花了 $200，又花 $1500` 绝不会变成公式。

行内 `$…$` 沿用 pandoc 的保守规则：开定界符后不能是空白、闭定界符前不能是空白、
闭定界符后不能紧跟数字、内容不跨空行。不满足就当成普通美元符号。

## 错误绝不静默，但也不过度惩罚

MathJax 有三种失败方式，其中危险的那种是**抛异常后整条跳过**，页面上只留下原始 LaTeX，
没有任何提示 —— 看起来就跟本来就是文字一模一样。所以 quietmd 不依赖 MathJax 自己报错，
而是渲染完**逐条核对每个公式槽里到底有没有长出 `mjx-container`**，并按严重程度分两级：

| | 什么情况 | 页面上 |
|---|---|---|
| **排不出来** | 语法错误，整条没法解析（括号没配对之类） | 红色虚线框 + 等宽原始 LaTeX |
| **含不认识的命令** | 命令拼错，或用了没装的宏包，但**公式其余部分照常渲染** | 橙色虚下划线，公式主体正常显示 |

<p align="center"><img src="docs/errors.png" width="760" alt="两级错误提示"></p>

分两级是因为惩罚不该一刀切。`\undefinedCmd{x} + \alpha^2 + \beta` 里只有一个命令不认识，
把整条作废等于连 α² 也不给看了。所以 MathJax 的 `noundefined` 包留着 ——
它把不认识的命令排成红字、其余照常渲染；而它留下的红字带 `fill="red"`，检测照样抓得到，
不会变成静默失败。`noerrors` 则**摘掉**了：它会把语法出错的公式整条伪装成普通文本，
那是唯一绝对不能发生的事。

措辞特意指向**文档**而不是阅读器 —— 说「渲染失败」会让人以为是工具坏了，
而绝大多数情况是公式本身有笔误。

投稿前想一次扫完全稿：

```console
$ quietmd paper.md --check
paper.md：3 处公式，1 处排不出来，1 处含不认识的命令
  [排不出来] 1. \frac{1}{
  [不认识的命令] 1. \undefinedCmdXYZ{x} + \alpha^2 + \beta
```

它不是静态扫描，是用无头 Chrome 真跑一遍 MathJax 再逐条核对。
只有全部渲染成功退出码才是 0，可以直接进脚本。

## 和 pandoc 的老实对比

同一份折磨测试文档，两边都渲染出来后用无头 Chrome 真跑一遍 MathJax
（`pandoc 3.9.0.2`，`--standalone --embed-resources --mathjax=file://…`）：

| | pandoc | quietmd |
|---|---:|---:|
| 渲染出的公式 | 38 | 38 |
| `\label` 生成编号锚点 | 0 | 3 |
| `\eqref` 生成可点击引用 | 0 | 6 |
| 标出有问题的公式 | 0 | 1 |

**pandoc 的数学解析一点毛病都没有** —— 它的 Markdown reader 原生就懂 math，
不是后处理，所以根本不会犯上面那张表里的错。如果你只要公式正确，pandoc 早就够用了。
差别只有两处：pandoc 默认没开 `tags:'ams'`，`\label`/`\eqref` 交叉引用不工作；
以及那条故意写坏的公式被 MathJax 的 `noundefined` 悄悄伪装成了普通文本，它不会告诉你。

VS Code 的 Markdown Preview Enhanced、Mathpix 的 markdown-it、Quarto 也一样 ——
数学都做得对。我没找到的是**会告诉你「这条公式没排出来」的阅读器**。那才是值得做的部分。

## 排版风格

八种，全部内嵌在页面里 —— 下拉框选，或按 `s` 循环，选择会记住。
`--style` 只决定初始值。换风格不会影响渲染结果：八种风格的公式计数完全一致。

| | 出处 | |
|---|---|---|
| `paper` | — | 暖白纸、衬线、侧边目录（默认） |
| `latex` | LaTeX `article` 类 | 窄栏、两端对齐、首行缩进、标题居中；装过 MacTeX 会优先用 Latin Modern / CMU |
| `book` | 传统书籍排版 | 米黄纸、首行缩进、标题居中、无侧栏 |
| `tufte` | [tufte-css](https://edwardtufte.github.io/tufte-css/) | `#fffff8`、Palatino、斜体不加粗的标题、正文靠左留出右白边 |
| `medium` | Medium 长文页 | 衬线正文配无衬线粗标题、字号大、行距宽松 |
| `github` | GitHub README | 系统无衬线、标题下分隔线、灰底圆角代码块 |
| `swiss` | 国际主义平面设计 | 无衬线、粗横线分节、强层级 |
| `manuscript` | 打字稿 | 等宽、双倍行距，适合校对和手写批注 |

<p align="center">
  <img src="docs/style-latex.png" width="270" alt="latex">
  <img src="docs/style-tufte.png" width="270" alt="tufte">
  <img src="docs/style-github.png" width="270" alt="github">
</p>

两处专门为中文做的适配，都是看截图发现的而不是想出来的：`latex` 加了
`text-justify:inter-word`，因为中文没有词间空格，默认的两端对齐只能靠拉**字距**来凑，
"行 内 ： 设" 会散开；`tufte` 加了 `font-synthesis:style none`，因为中文字体没有真斜体，
浏览器合成的伪斜体（整个字歪着）很难看 —— 关掉之后拉丁走真斜体、中文保持正体。

## 其余功能

**数学** —— `$…$` `$$…$$` `\(…\)` `\[…\]`、amsmath 全套环境、`\newcommand`（跨公式生效）、
`\label` + `\eqref` 自动编号与可点击交叉引用，以及 MathJax 的全部扩展包
（mhchem、physics、mathtools…）。

**Markdown** —— GFM 表格、删除线、任务列表、脚注、定义列表、YAML front matter、
Pygments 代码高亮、自动链接。

**阅读** —— 侧边目录跟随滚动高亮、阅读进度条、明暗跟随系统（`t` 手动切换）、字号调节、
页面宽度四档（`[` `]`）、超长公式横向滚动带渐隐提示、双击公式复制 LaTeX、
打印/存 PDF 样式、刷新后回到原位置。

**产物** —— HTML 就放在源文件旁边（`paper.md` → `paper.html`），好找、也方便直接发给别人。
如果同名文件已经存在而且不是 quietmd 生成的，会改写成 `paper.quietmd.html`，绝不覆盖你自己的文件；
目录不可写（只读挂载之类）则退回 `~/.cache/quietmd/`。图片 base64 内嵌，所以真的是单个文件；
源文档里的 `<script>`/`<iframe>` 会被剥离；MathJax 内嵌，首次下载之后全程不联网。
你大概会想把 `*.html` 加进 `.gitignore`。

**键盘** —— `j`/`k` 滚动 · `g`/`G` 首尾 · `t` 明暗 · `s` 风格 · `h` 目录 ·
`[` `]` 宽度 · `⌘F` 连公式的 LaTeX 源码也能搜到。

## 安装

需要 [uv](https://docs.astral.sh/uv/)（管 Python 依赖）和一个 Chromium 系浏览器
（只有 `--check` 和 `verify.sh` 用得到；平时看文档任何浏览器都行）。

```console
$ git clone https://github.com/chenzhan4321/quietmd.git
$ cd quietmd
$ ./install.sh
```

MathJax（2.2 MB）没放进版本库 —— 第一次运行时自己下载，带镜像回退和大小校验，之后全程离线。

**macOS：双击 `.md` 用它打开**

```console
$ ./install.sh --macos-app
```

会编译一个 AppleScript 应用（只有这种应用能接收 Finder 的「打开文档」事件）、
声明 Markdown 文档类型，装了 `duti` 的话顺便设为默认打开方式。
注意 `duti -x md` 的查询结果有缓存、可能一直显示旧的，
真正的检验是双击一个 `.md`，看 `~/.cache/quietmd/` 里有没有出现对应的 HTML。

想把 `.md` 交回给别的应用：`duti -s <bundle id> net.daringfireball.markdown all`。

## 自己验证

上面这些说法不用信我，有脚本：

```console
$ sh verify.sh
```

它渲染一份折磨测试文档，用无头 Chrome 真跑一遍 MathJax，核对 15 件事：
下标有没有被 Markdown 解析器吃掉、`\\` 换行、裸 `\begin{align}`、
`\label`+`\eqref` 编号与交叉引用、`\newcommand` 跨公式生效、货币金额**没有**变成公式、
代码块原封不动、没有占位符残留、MathJax 确实内嵌。
预期结果：15 项通过，并且**恰好有一条公式失败** —— 那是测试文档里故意写坏的。
哪天这个失败消失了，说明错误检测本身坏了。

## 许可

MIT，见 [LICENSE](LICENSE)。

MathJax 由程序在运行时下载，不属于本仓库，它由 MathJax Consortium 以
[Apache-2.0](https://github.com/mathjax/MathJax/blob/master/LICENSE) 发布。
`tufte` 风格参照 [tufte-css](https://github.com/edwardtufte/tufte-css)（MIT）。
