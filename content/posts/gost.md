---
title:  "如何部署 HTTPS 代理服务"
date: 2020-01-12T19:43:00+08:00
draft: false
---

## 前言

某天，看到了陈皓的推上发了一片他的 blog。作为从他的多篇 blog 中受益的我来说，下意识觉得肯定很靠谱，于是拜读了一下，就有了这篇实践文章。

## 为什么用 HTTPS 代理

在[攻略](https://haoel.github.io/)里已经讲得很清楚了，外加自己数次 shadowsocks 被 ban 的经历，觉得有必要换一种更安全的代理方式。

## 怎么部署 HTTPS 代理

### gost

[gost](https://github.com/ginuerzh/gost) 是[攻略](https://haoel.github.io/)中，感觉最推荐的工具。一开始我对它的理解也有问题，刚开始理解成他是类似 kcptun 的方式，依然是依赖 shadowsocks。实际上 gost 是实现了多种代理，也就是有它就可以不用其他代理了。
我一直不太喜欢通过不断套壳来加速/混淆 shadowsocks 的方式，总觉得链路太长，带来的问题就会更多。

### 步骤

* 直接下载 gost repo 下的最新 release，虽然，我本地甚至 vps 上都有 golang 环境，不过，直接下载最省心了。这里下载的是 2.9.0 版本。
* certbot 在裸的 vps 上直接按 certbot 的步骤走是过不了的。。。需要：
    1. 启动一个 nginx，具体是参照[这篇](https://www.digitalocean.com/community/tutorials/how-to-install-nginx-on-debian-9)。当然，这里的前提是有自己一个域名，并把 A name 指到这个 vps 上。
    1. 验证通过域名可以访问
    1. 停止 nginx
    1. 用 certbot 的 --standalone 的方式，成功后会生成证书
* 这里我没有用 docker 来部署，而是用了 systemd，直接创建了一个 systemd uint，方法类似 kcptun 的。不太一样的是，由于证书需要更新，所以，这个 unit 还需要一个 reload 方法。从[这篇介绍](http://www.ruanyifeng.com/blog/2016/03/systemd-tutorial-commands.html)里，可以学到不少关于 systemd 使用的细节，顺带提一下这个博主的文章质量也十分高，推荐订阅。
    1. 创建一个 `/lib/systemd/system/gost.service` 文件，填入一下内容，域名换成自己的。

        ```text
        [Unit]
        Description=gost service
        After=network.target
        StartLimitIntervalSec=0

        [Service]
        Type=simple
        Restart=always
        RestartSec=1
        User=root
        PIDFile=/home/admin/gost.pid
        ExecStart=/home/admin/bin/gost -L "http2://xxx:yyy@0.0.0.0:443?cert=/etc/letsencrypt/live/example.com/fullchain.pem&key=/etc/letsencrypt/live/example.com/privkey.pem&probe_resist=code:404"
        ExecReload=/bin/kill -HUP $MAINPID

        [Install]
        WantedBy=multi-user.target
        ```

    `ExecStart` 就是简化了[攻略](https://haoel.github.io/)里的 docker 方式。`ExecReload` 就是 kill。
    1. 通过 `systemctl start|status|restart|enable gost` 来测试一下是否成功
    1. 配置 crontab 来更新证书。没有用 systemd 是因为我不太熟。

        ```text
        0 0 1 * * /usr/bin/certbot renew --force-renewal
        5 0 1 * * systemctl restart gost
        ```

* 上述搞定以后，nginx 就可以直接 stop 再 disable 了。

* 配置客户端。这个就简单了，直接参照[攻略](https://haoel.github.io/)，即可。原理很简单，因为 gost 实现 shadowsocks 协议本身就是用的 shandowsocks golang 版本的实现。所以，以下命令就是本地启动一个 shadowsocks server。然后，再配置你的客户端，增加一个密码匹配的本地服务器配置即可。

    ```text
    .\bin\gost-windows-amd64.exe -L=ss://aes-128-cfb:passcode@:1984 -F=https://xxx:yyy@example.com:443
    ```

PS: 本人还不知道怎么在 Android 上不 root 的话配置全局 https 代理，也不知道 iOS 上没有美区账号怎么配。再就是也不知道 Windows 10 上怎么优雅配置开机启动脚本。这些待研究。。。

## 续

上面说到移动端的问题。翻了一圈发现 https 代理的客户端支持都不太好。gost 本身似乎有些问题，也可能是我的使用姿势问题，总之不用本地 gost 连接远程 gost，鉴权就会出错。

这两天，趁着放假了，稍微又折腾了一下。先是在家里 nas 上部署了一个 gost http 代理，用最简单的 nohup + ctrl-D 来维持。编译的时候选 GOARCH=arm64 就行了。试运行了一天，Android 自带的弱鸡 http 代理运行良好，但是总全局翻不是很爽。于是，把 http 换成了 ss 连接远程 https。类似把 Windows 上的本地服务搬到了 nas 上。于是，又简单的通过两层端口转发，nas -> 内网路由 -> 光猫路由，这样通过公网 IP，也可以把 nas 当 ss server 来用了。

剩下就是 ddns 的问题。搜了一圈，似乎 Cloudflare 的 api 是比较靠谱的方案。正好官方有个 flarectl，编完搞到 nas 上，写了个小脚本，再次体验了一下 bash 的各种神奇（坑），终于让我回想起以前看到有人做字符串比较时候的特殊写法的缘由。`[ $a != $b ]` 这种改为 `[ $a != $b* ]` 是为了避免行尾 "\r" "\n" 之类字符的处理。不过，解绑 name server 还需要一段时间。最终效果待验证。

对了，在 nas 上获取本机公网 IP 的办法我目前就是用了一个 curl 某个提供 IP 的第三方地址的办法，总感觉不知道哪天可能旧连不上或者遇到些问题挂了。
