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

    ![goenv](/posts/images/20200706172327.png)

1. TiDB 代码可以不放在 GOPATH 下开发，因此，TiDB 代码放在哪都可以。我一般就是创建一个叫 work 的目录，把各种代码都丢在里面。
1. 打开 Goland/IDEA，我用的是 IDEA，因为，平时要看些其他语言的代码。
1. 用 IDEA 打开，选 tidb 的目录

    ![src](/posts/images/20200706174108.png)

1. 这时候 IDEA 一般能自动提示设置 GOROOT 和启用 Go Modules，都根据推荐的来

自此环境搭建就完成了。

## 切入点

刚开始的时候，有人推荐我从 session 这个包开始看，不过，经历了一些之后，个人感觉，有两个比较好的切入点，一个是 `main` 函数，一个是 `dispatch` 函数。

### main 函数

TiDB 的 `main` 函数在 [link](https://github.com/pingcap/tidb/blob/6b6096f1f18a03d655d04d67a2f21d7fbfca2e3f/tidb-server/main.go#L160) 看到。从上到下可以大体过一下启动一个 tidb-server 都做了什么。

![main](/posts/images/20200706220211.png)

从上到下分别是

* 解析 flag
* 输出版本信息并退出
* 注册 store、监控
* 配置文件检查
* 临时文件夹的初始化等
* 设置全局变量、CPU 亲和性、日志、trace、打印 server 信息、设置 binlog、设置监控
* 创建 store 和 domain

    这里的 `createStoreAndDomain` 比较重要，重要的后台线程都在此创建。

* 创建 server，注册停止信号函数
* 启动 server

    `runServer` 里的 `srv.Run()` 真正的把 tidb-server 给 run 了起来。
    ![run](/posts/images/20200706221611.png)
    在 `Run()` 函数的这里，server 不断监听网络请求，出现新连接请求就创建一个新连接，使用一个新 goroutine 来持续为它提供服务。

* 再这后面就是当 server 需要停止后，进行一些清理工作，最终把日志写出去。

至此，整个 `main` 函数结束。使用 `main` 函数可以看到一个 server 从创建到销毁的全生命周期。

另外，结合 IDEA 还可以轻松的启动、调试 TiDB。点击下图这个三角

![run](/posts/images/20200706222247.png)

![run](/posts/images/20200706222457.png)

会弹出 run 和 debug `main` 函数的选项，本质就是启动了一个使用默认配置的 TiDB，TiDB 默认用 mocktikv 作为存储引擎，因此可以单机启动，方便做各种测试验证。

至于怎么修改配置来启动、调试，会在后续的系列文章中介绍。

### dispatch 函数

从 `srv.Run()` 里向后不远，就到了另一个适合做切入点的函数 `dispatch`
