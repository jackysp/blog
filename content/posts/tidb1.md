---
title:  "如何阅读 TiDB 的源代码（一）"
date: 2020-07-06T16:51:00+08:00
---

## 背景

TiDB 有很多源码阅读文章，人称《二十四章经》。不过，介绍的角度是从宏观到微观来的，本系列试图用更容易上手的角度来介绍如何阅读 TiDB 的源代码。想达到的目的是，

1. 可以让读者自己上手读 TiDB 的代码，而不是通过别人写好的文章来被动理解代码
1. 提供一些常用的查看代码里细节的例子，比如，查看某变量的作用域等

毕竟，代码经常变，而方法基本是不变的。

为什么选 TiDB 来读呢？

1. TiKV、PD 我都不懂
1. TiDB 是跟用户直接打交道的入口，也是最容易被问到的
1. TiDB 可以独立运行、调试，如果读完代码想跑几个 SQL 验证一下，也可以很简单地做到

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

    这里的 `createStoreAndDomain` 比较重要，重要地后台线程都在此创建。

* 创建 server，注册停止信号函数
* 启动 server

    `runServer` 里的 `srv.Run()` 真正的把 tidb-server 给 run 了起来。
    ![run](/posts/images/20200706221611.png)
    在 `Run()` 函数的这里，server 不断监听网络请求，出现新连接请求就创建一个新连接，使用一个新 goroutine 来持续为它提供服务。

* 再这后面就是当 server 需要停止后，进行一些清理工作，最终把日志写出去。

至此，整个 `main` 函数结束。使用 `main` 函数可以看到一个 server 从创建到销毁的全生命周期。

另外，结合 IDEA 还可以轻松的启动、调试 TiDB。点击下图这个三角

![run1](/posts/images/20200706222247.png)

![run2](/posts/images/20200706222457.png)

会弹出 run 和 debug `main` 函数的选项，本质就是启动了一个使用默认配置的 TiDB，TiDB 默认用 mocktikv 作为存储引擎，因此可以单机启动，方便做各种测试验证。

至于怎么修改配置来启动、调试，会在后续的系列文章中介绍。

### dispatch 函数

从 `srv.Run()` 里向后走不远，就到了另一个适合做切入点的函数 `dispatch`。

`dispatch` 函数有几个特点，

1. 只有来自客户端的请求才会进入 `dispatch` 函数，也就是说，从这里开始看，执行的都是用户的请求，以此为起点打断点的话，可以方便地过滤掉内部线程执行的 SQL。
1. 从这里开始，各种请求会进行分发，进入不同的处理逻辑，因此，从这开始的用户请求也是不会被漏掉的。不会出现，比如，看了半天 text 协议的代码，结果用户实际使用的是 binary 的协议。
1. `dispatch` 本身处在非常靠前的位置，也就是它的参数基本来自客户端的第一手信息，如果是 text 协议，直接读参数还可以解析出 SQL 文本。

![dispatch1](/posts/images/20200707150344.png)

`dispatch` 一开始主要就是获取 token，也就是对应 token-limit 这个参数，获取不到 token 的请求不能执行，这也就是，为什么能创建很多连接，但是最多同时执行的 SQL 默认只有 1000 个。
然后，就进入了最重要的一个 switch case，

![dispatch2](/posts/images/20200707150736.png)

在这些 command 就是 MySQL 协议的 command，所以，TiDB 到底实现了哪些，在这里就一目了然了。具体可以跟 [link](https://dev.mysql.com/doc/internals/en/text-protocol.html) 进行对比（这个链接只有 text 协议的），全部的可以看下图。

![dispatch3](/posts/images/20200707151452.png)

`dispatch` 里最重要的是 `mysql.ComQuery` 和 `mysql.ComStmtPrepare`、`mysql.ComStmtExecute`、`mysql.ComStmtClose` 三兄弟。后者其实
更多地在实际生产中使用，所以更加重要。 `mysql.ComQuery` 其实一般只有一些简单测试验证中使用。

`dispatch` 由于是与客户端交互的入口，因此，它可以方便地统计数据库处理了多少请求。从监控统计得到的所谓 QPS，其实就是这个函数的每秒执行次数统计。这里，就引入
一个问题。有的请求，比如，multi-query 请求，像是 select 1; select 1; select 1; 这种多条语句拼在一起发过来的，对于 dispatch 来说，只是一次请求，对于
客户端来说，可能就是三次。如果使用 binary 协议，有些客户端会先 prepare 语句，再 execute 语句，最后 close 语句，相当于，对于客户端来说只执行了一个 SQL，
对于数据库其实是完成了三次请求。

一句话总结，用户感知到的 QPS 与 `dispatch` 函数调用次数很可能是对不上的。因此，在后面的版本里，TiDB 监控里的 QPS 面板被改成了 CPS，即 Command Per Second，
每秒执行的 command 数量。

看 `dispatch` 的调用者，也可以看到信息来解释一些经常被大家问到的问题，

![dispatch4](/posts/images/20200707154120.png)

1. 如果 `dispatch` 遇到了 EOF 错误，一般是客户端自己断开了，那数据库连接也没有必要保留，就断开了。
1. 如果发生 undetermined 错误（指的是事务进行了提交，但是，不知道是提交成功还是失败了，需要人工介入验证事务是否提交成功），此时，应该立刻人工介入，本连接也会关闭。
1. 写 binlog 失败并且 `ignore-error = false`，之前的处理是 tidb-server 进程不退出，但是不能提供服务。现在是 tidb-server 直接会退出。
1. 对于所有其他 `dispatch` 错误，连接都不会断开，会继续提供服务，但是会把失败信息用日志的形式打出来："command dispatched failed"，可以说这是
TiDB 最重要的日志之一。

# 总结

至此，从环境搭建入手到找到合理切入点开始读代码的介绍就告一段落了。系列的后面会介绍一些，诸如，配置（调整、默认配置值）、变量（默认值、作用域、实际作用范围，如何生效）、
哪些语法是支持的等等。敬请期待。
