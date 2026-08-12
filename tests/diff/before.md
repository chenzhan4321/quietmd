# 论文稿

## 方法

我们用余弦相似度衡量两个句向量的接近程度：

$$\cos(u, v) = \frac{\langle u, v\rangle}{\|u\|\,\|v\|}$$

这一段没有改动，应该显示为正常颜色。

## 实验

结果是 0.6948，比基线好。

$$\alpha_i = \frac{\log \hat{p} \cdot u_i}{\sigma_i}$$
