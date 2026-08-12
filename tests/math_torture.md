---
title: 数学渲染折磨测试
author: mdview 自检
date: 2026-08-12
---

# 数学渲染折磨测试

下面每一条都是 Typora / iA Writer 类编辑器常见的翻车点。

## 1. 下划线不该变成斜体

行内：设 $a_1, a_2, \ldots, a_n$ 为一列实数，令 $S_n = \sum_{i=1}^n a_i$，
则 $\lim_{n\to\infty} S_n/n = \bar a$。

$$
x_{i,j} = \frac{\partial^2 f}{\partial u_i \partial u_j}, \qquad
M_{ab}^{cd} = \delta_a^c \delta_b^d - \delta_a^d \delta_b^c
$$

若上面有任何一处的 `_` 被吃掉、变成斜体或下标丢失，就是渲染器坏了。

## 2. 双反斜杠换行不该被吞

$$
\begin{aligned}
f(x) &= (x+1)^2 \\
     &= x^2 + 2x + 1 \\
     &= x(x+2) + 1
\end{aligned}
$$

三行必须分三行。只显示一行 = `\\` 被 Markdown 吃了。

## 3. 裸 amsmath 环境（不包在 `$$` 里）

\begin{align}
\nabla \times \mathbf{E} &= -\frac{\partial \mathbf{B}}{\partial t} \label{eq:faraday} \\
\nabla \times \mathbf{B} &= \mu_0 \mathbf{J} + \mu_0\varepsilon_0 \frac{\partial \mathbf{E}}{\partial t} \label{eq:ampere}
\end{align}

\begin{equation}
\zeta(s) = \prod_{p \text{ prime}} \frac{1}{1 - p^{-s}} \label{eq:euler}
\end{equation}

## 4. 自动编号与交叉引用

由 \eqref{eq:faraday} 与 \eqref{eq:ampere} 可得波动方程；
欧拉乘积见 \eqref{eq:euler}。**这三个引用必须显示成公式号，不是问号或原文。**

## 5. `\newcommand` 自定义宏

$$\newcommand{\Real}{\mathbb{R}}\newcommand{\abs}[1]{\left\lvert #1 \right\rvert}\newcommand{\dd}{\,\mathrm{d}}$$

定义之后，后面所有公式都该认得它们：
对任意 $x \in \Real^n$，有 $\abs{x} \geq 0$，且
$$\int_{\Real} e^{-x^2} \dd x = \sqrt{\pi}.$$

## 6. 美元符号不是公式

这台机器花了 $200，另一台 $1500，加起来 $1700。上面**不能**出现斜体数学字体。

转义的美元符号：\$99.99 也应原样显示。

## 7. 代码块里的一切都不该被渲染

```bash
echo $PATH
awk '{s += $2} END {print s}' data.txt
sed -i 's/\[foo\]/bar/g' file.md
```

行内代码：`$HOME/.config`、`\begin{align}`、`$$x^2$$` —— 全部原样。

## 8. 大型结构

$$
\mathbf{A} = \begin{pmatrix}
a_{11} & a_{12} & \cdots & a_{1n} \\
a_{21} & a_{22} & \cdots & a_{2n} \\
\vdots & \vdots & \ddots & \vdots \\
a_{m1} & a_{m2} & \cdots & a_{mn}
\end{pmatrix}
$$

$$
f(x) = \begin{cases}
x^2 \sin(1/x), & x \neq 0 \\
0, & x = 0
\end{cases}
$$

$$
\underbrace{\left( \sum_{k=0}^{\infty} \frac{z^k}{k!} \right)}_{e^z}
\cdot \overbrace{\prod_{j=1}^{m}\left(1+\frac{1}{j}\right)}^{m+1} \; \xrightarrow{\;m\to\infty\;} \; \infty
$$

## 9. 超长公式必须能横向滚动，不能撑破版面

$$
\Gamma(z)\Gamma(1-z) = \frac{\pi}{\sin \pi z} = \int_0^\infty \frac{t^{z-1}}{1+t}\dd t = \sum_{n=-\infty}^{\infty} \frac{(-1)^n}{z-n} = \lim_{N\to\infty} \frac{1}{z}\prod_{n=1}^{N}\frac{n^2}{n^2 - z^2} \cdot \frac{N!\,N^z}{z(z+1)\cdots(z+N)}
$$

## 10. 表格里的公式

| 分布 | 密度 $p(x)$ | 期望 | 方差 |
|---|---|---|---|
| 正态 | $\frac{1}{\sigma\sqrt{2\pi}}e^{-(x-\mu)^2/2\sigma^2}$ | $\mu$ | $\sigma^2$ |
| 泊松 | $\frac{\lambda^k e^{-\lambda}}{k!}$ | $\lambda$ | $\lambda$ |
| 指数 | $\lambda e^{-\lambda x}$ | $1/\lambda$ | $1/\lambda^2$ |

## 11. 列表与引用块里的公式

1. 若 $p \mid ab$ 且 $p$ 为素数，则 $p \mid a$ 或 $p \mid b$
2. 由此得唯一分解：$n = \prod_i p_i^{e_i}$

> **定理（Cauchy–Schwarz）**：$\left|\langle u, v\rangle\right|^2 \leq \langle u,u\rangle \cdot \langle v,v\rangle$，
> 等号成立当且仅当 $u, v$ 线性相关。

## 12. 故意写错的公式（必须**显眼报错**，不能假装成功）

$$ \thisCommandDoesNotExist{x} + \frac{1}{ $$

页面右下角应该弹出红色提示，告诉你有几个公式挂了。静默失败是最危险的。

## 13. 转写与非拉丁文字

满文转写 ᡥᠠᠨ、希腊 $\alpha\beta\gamma\delta$、希伯来 $\aleph_0 < 2^{\aleph_0}$、
中文夹排 $E = mc^2$ 的行高应当整齐。
