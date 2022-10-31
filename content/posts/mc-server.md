---
title:  "如何用 Multipass 搭建 Minecraft Bedrock Server"
date: 2022-05-02T19:05:00+08:00
draft: false
---

## 背景

最近家里两个孩子都喜欢起 Minecraft，他们同龄的孩子也有在玩的。虽然之前买了 Switch 版本，但是，它的联网能力太差，设备性能也太差，体验不好。于是，有了自建一个服务器的想法。当然，也可以好友间联机，但是对于 Host 一方一旦下线，游戏就结束，这种体验还是不如有一个始终在线的服务器来的好。

对于版本的选择，目前有网易版、官方 Java 版和基岩版。按我以前的了解，网易版有各种防沉迷的监管，于是 pass，Java 版自建 Server 好像都是通过第三方启动器来实现的，有点儿像盗版，于是，最后选了基岩版。选基岩版的另一个理由是，记得它前身是手游版的 Minecraft，后来微软[支持了更多的平台](https://minecraft.fandom.com/zh/wiki/%E5%9F%BA%E5%B2%A9%E7%89%88?variant=zh)，通用性是最好的。再就是，它内核是 C++ 编写的，在性能和资源利用率上应该都会好一些。

## 下载服务器软件

我这里下载的是 [Ubuntu 版本](https://www.minecraft.net/en-us/download/server/bedrock)，虽然，我也下过 Windows 版本，也可以跑起来，但是做服务器的话，我没管理过 Windows Server，而且 Windows 版本本身在使用时也会有一些小坑，这里就不在详述了。

## 内网服务器

本来打算用老的 Thinkpad，后来没找到，只找到了老的 Macbook，更新搞起来之后发现老的 Macbook 还能再战几年的样子，比 Thinkpad 强多了。于是，虚拟机搞起。结果查了下 Ubuntu Server，现在不支持直接下载 iso，要走 Multipass 启动。

Multipass 是个啥？

Ubuntu 家开发的一个轻量级虚拟化平台。Multipass 分 multipass 和 multipassd，一个前台，有 GUI 和 CLI，一个后台，需要 root 权限。可以直接下载，也可以用 brew cask 安装。

Multipass 好像只能安装 Ubuntu Server，而且有一定的定制化，比如，安装完成后自动搞一个叫 ubuntu 的用户，有自动公私钥配对。装好后，直接起就有一个 1C 1GB 的虚拟机，叫 primary，primary 默认 mount 用户的 home 目录。

multipassd 更偏下层是可插拔的虚拟化 hypervisor，默认是支持 hyperkit 和 qemu，hyperkit 给 intel macOS 用，qemu 给 m1 用。

multipassd 也可以用 Virtualbox 做 backend 的 hypervisor，这种其实更加推荐，因为它带桥接功能，否则，都靠端口映射也太麻烦了。不是说 qemu 不带桥接，只是 Multipass 的官网文档给了一篇很无脑的 [Virtualbox 桥接教程](https://multipass.run/docs/set-up-the-driver)，跟着抄就行了。

于是，先搞起 Virtualbox，不得不说 Oracle 在这里还是挺良心的，它依然可以免费使用。然后，根据上面链接一步一步抄。需要注意一下，第一步 `sudo multipass set local.driver=virtualbox` 后最好重启一下机器，感觉像是变量没热生效。否则，创建出来的 primary 还是用的老 backend。因为有了一个默认的虚拟机，我不想再搞一个来占用额外资源。另外，还有几点需要注意一下：

1. 关于修改 primary 配置，我没找到用 Multipass 的修改方式，用的 vbox 的 `sudo VBoxManage controlvm "primary" --cpus 2 --memory 4096`（内存单位是 M）来修改的。
1. Multipass 的 primary 或者说 mount 点在某些情况下会自动 unmount，导致错误。因此，Minecraft 的数据不能长久放在 mount 里，会 core dump。

解压好服务器文件，进 tmux/screen 启动起来就好了。

最后就是合上笔记本也能继续工作了，用的是 [Amphetamine](https://apps.apple.com/us/app/amphetamine/id937984704?mt=12)，App Store 上就有，注意要把默认的允许系统在屏幕关闭后休眠去掉，去掉的时候会有些告警，自己知道就好了。

**更新：**

想 systemd 启动的话，可以参考[这个 gist](https://gist.github.com/gatopeich/36ed7fab3850367bbcd8e6f40becd4e5)。
因为 console 实际有些命令，比如 stop 这种，真正实现了 graceful shutdown，所以，还是有必要用的，所以要依靠 screen session 来创建。
再就是启动 server 有一些环境依赖，最好写一个小脚本来启动，比如：

```bash
#!/bin/bash

cd /home/user/bedrock-server
LD_LIBRARY_PATH=. ./bedrock_server
```

如果用绝对路径会有 core dump。

## 公网服务器

公网服务器的选择无非是内网映射到公网，或者是买一个云服务器。鉴于安全担忧，最后还是选择了买一个云服务器。虽然官网写的是支持 Ubuntu，但是，我买的 Debian 服务器运行起来也毫无问题。唯一要注意的是，基岩版走的是 UDP 协议，联通 5G 禁掉了 UDP，所以，没有 WiFi 连不上。

## 服务器监控

想看到服务器的状态就需要监控。对于云服务器也是，因为提供商提供的信息可能不全。我用的是 [Grafana Cloud](https://grafana.com/products/cloud/)。

使用免费版就好了，跟着 guide 选一个 linux server integration，然后，在需要监控的服务器里执行安装 Grafana Agent、验证就好了。注意把 Grafana Agent 配置文件里的 hostname 改个名字，就是个 label，方便区分不同 server。

Grafana Agent 我理解是一个轻量化的 node exporter 外加一些 Prometheus 的功能，不过它也可以 remote write，所以，不用担心盘会爆。