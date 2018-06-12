---
title: "如何理解 CAP 定理"
date: 2017-12-20T22:21:06+08:00
---

# 背景

CAP 定理也是近些年最热的定理之一了，谈分布式必扯 CAP 。但是我觉得没有理解透彻，于是就想写一篇 blog 来记录下自己的理解。有新的理解会更新内容。

# 理解

读了下这篇[文献](https://static.googleusercontent.com/media/research.google.com/zh-CN//pubs/archive/45855.pdf)的第一部分。

> The CAP theorem [Bre12] says that you can only have two of the three desirable properties of:
>
> * C: Consistency, which we can think of as serializability for this discussion;
> * A: 100% availability, for both reads and updates;
> * P: tolerance to network partitions.
>
> This leads to three kinds of systems: CA, CP and AP, based on what letter you leave out.

说下我的理解，以三台机器（ x ，y ，z ）组成的网络为例：

* C: 三台机器看起来就像一台一样，一个人对一台机器的增删改查操作，始终应该是一致的。也就是从 x 读了数据，接着从 y 读，结果一样。从 x 写了数据，接着从 y 读也读到了这个新的写入。在 wikipedix 里还特别说明，稍过一段时间从 y 读到刚从 x 写的数据也是可以的（最终一致）。
* A: 三台机器作为一个整体必读都可以读和写，部分挂掉没关系，必须可读也可写。
* P: x ，y 和 z 之间网络断了，任何机器不能或者但拒绝提供服务，既不可读也不可写。

这里 C 是最好理解的。A 和 P 的概念比较模糊，容易混淆。

下面说三种组合：

如果 x ，y 和 z 之间网络断了，

* CA: 让数据一致，x 写数据，y 可读到（ C ），让系统即使是只有 x ，y 部分继续提供服务，可读可写（ A ），只能容忍 z 不提供服务，不能读写，也就不能返回错误的数据（ P 丢失）。
* CP: 让数据一致 （ C ），让三台机器都可提供服务（可读也算）（ P ），只能容忍 x ，y ，z 都不能写（ A 丢失）。
* AP: 让三台机器都可写（ A ），让三台机器都可提供服务（可读也算）（ P ），只能容忍 x ，y 写的数据到不了 z ，z 会返回跟 x ，y 不一致的数据（ C 丢失）。

CA 是 paxos/raft ，是大多数协议，牺牲了 P ，少数派节点完全沉默。CP 是只读系统，如果什么系统是只读的，之间有没有网络其实也无所谓，网络分区容忍无限大。AP 适合只追加不更新的系统，只 insert 不 delete 和 update，最后把结果合并到一起，也能用。