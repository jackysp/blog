---
title:  "如何部署 shadowsocks server"
date: 2018-09-27T15:48:00+08:00
draft: true
---

shadowsocks 的 server 端有多个不同的版本，最初的版本是用 python 写的，后来各路爱好者又都做了自己喜爱语言的实现。

在这众多的实现中，个人认为最可靠稳定的是最初的 python 实现版，理由很简单，用的人最多。
golang 版本据说是功能最多，性能也很好的，总之非常强大。可能得益于 golang 本身的高性能，实现方便等特点。
还有个实现是用 libev 来实现的，纯 c 的实现，也有很好的性能并且十分轻量。

另外，如何更新服务端也是一个对于使用 shadowsocks 的用户需要面对的问题。由于众所周知的原因，服务端还是应该多更新。
如果是 python 实现，可能可以通过 pip 来安装，这个我没有确认过，golang 的也许就需要一套 golang 的编译环境，然后再
go get -u 了。而 libev 的更新我们则可以通过 debian 系的 apt 来更新，apt 已经包含了 libev 的 shadowsocks。至于
redhat 系的 yum 有没有我没去确认过。

介绍过了之后，简单讲下步骤，具体非常简单：

1. 部署一个 debian 9 或者 ubuntu 17 的 vps，在 vultr 等主流提供商应该都有。假设这里用的是 debian 9。
1. `apt install shadowsocks-libev` 安装。
1. `vim /etc/shadowsocks-libev/config.json` 编辑下配置。
1. `systemctl restart shadowsocks-libev` 重启服务以生效。

这样就完成了。服务是默认随机器启动的，重启也不用担心。另外，关于加速，推荐使用 tcp bbr，而且这个在 debian 9 上是
默认打开的，根本不需要额外设置。也就是上述四步就已经搭建好了轻量、高速的 shadowsocks。