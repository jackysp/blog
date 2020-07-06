---
title:  "如何阅读 TiDB 的源代码（一）"
date: 2020-07-06T16:51:00+08:00
---

## 背景

TiDB 有很多源码阅读文章，人称《二十四章经》。不过，介绍的角度是从宏观到微观来的，本系列试图用更容易上手的角度来介绍如何阅读 TiDB 的源代码。想达到的目的是，

1. 可以让读者自己上手读 TiDB 的代码，而不是通过别人写好的文章来被动理解代码
1. 提供一些常用的查看代码里细节的例子，比如，查看某变量的作用域等

毕竟，代码经常变，而方法基本是不变的。

## 准备工作

1. 一台开发机

    TiDB 是一个纯 Golang 的工程，它不仅可以方便的在 Linux、MacOS 进行开发，也可以在 Windows 下开发。本文中所使用的环境就是 Windows 10。

1. TiDB 源代码一份，可以从[官方 repo](https://github.com/pingcap/tidb) 下载

1. [Golang](https://golang.org/) 环境，跟着官网走就行，很简单

1. Goland 或者 IntelliJ IDEA + Golang 插件

    我实际体验感受两者没有什么区别。为什么没推荐 VSCode + Golang 插件呢？主要是我用 JetBrains 全家桶习惯了，而且商业软件确实比开源软件质量要高。要长期使用的话建议付费，学生的话可以免费使用，不过每年要 renew 一下 license。

## 环境搭建

1. 安装好 Golang 环境后，记得设置下 GOPATH，通常就是，

    ![goenv](/content/posts/images/20200706172327.png)

1. TiDB 代码可以不放在 GOPATH 下开发，因此，TiDB 代码放在哪都可以。我一般就是创建一个叫 work 的目录，把各种代码都丢在里面。
1. 打开 Goland/IDEA，我用的是 IDEA，因为，平时要看些其他语言的代码。
1. 用 IDEA 打开，选 tidb 的目录

    ![src](/content/posts/images/20200706174108.png)

1. 这时候 IDEA 一般能自动提示设置 GOROOT 和启用 Go Modules，都根据推荐的来

自此环境搭建就完成了。
