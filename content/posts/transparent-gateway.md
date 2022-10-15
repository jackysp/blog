---
title:  "如何部署安全的透明网关"
date: 2022-10-12T21:07:00+08:00
draft: false
---

## 背景

搬家之后，家里需要上网的设备增加了不少。但是，我又不想每个设备都配置代理，于是，就想到了透明网关。

## 透明网关

搜了一圈之后，发现最简单的就是用 clash 的 premium 版本，虽然，我不知道什么时候 clash 出了个 premium。
主要是参考[这篇](https://www.cfmem.com/2022/05/clash.html)。比设置一波 iptables 要简单很多。

### 网络拓扑

家里有个 10 年的 Thinkpad x230 正好用来搞这个。简单画一下拓扑图。

Router1 是带路由功能的光猫，Router2 是一个普通的路由器，网关和 DNS 指向 Thinkpad，Thinkpad 上
跑一个 Linux，做透明网关，上面跑 clash。

```txt
                                 +------------+
                                 |            |
                                 |  Internet  |
                                 |            |
                                 +-----+------+
                                       |
                                 +-----+------+
                                 |            |
                      +----------+  Router1   +-----------+
                      |          |            |           |
                      |          +------------+           |
                      |                                   |
                      |                                   |
                +-----+-----+                       +-----+------+
                |           |                       |            |
     +----------+  Router2  +----------+            |  Thinkpad  |
     |          |           |          |            |            |
     |          +-----+-----+          |            +------------+
     |                |                |
     |                |                |
     |                |                |
+----+-----+     +----+-----+    +-----+-----+
|          |     |          |    |           |
|   Mac    |     |  iPad    |    |  iPhone   |
|          |     |          |    |           |
+----------+     +----------+    +-----------+
```

### Clash 配置里添加 DNS 部分

```yaml
dns:
enable: true
listen: 0.0.0.0:53
enhanced-mode: fake-ip
nameserver:
  - 114.114.114.114
fallback:
  - 8.8.8.8
```

### Clash tun 功能部分

```yaml
tun:
enable: true
stack: system # or gvisor
dns-hijack:
  - any:53
  - tcp://any:53
auto-route: true
auto-detect-interface: true
```

流量转发只需要 Thinkpad 编辑 `/etc/sysctl.conf` 添加 `net.ipv4.ip_forward=1`，然后，`sysctl -p` 生效。
然后，把 Router2 网关、DNS 指向 Thinkpad 就好了。

## 网络协议

本来使用原生 http2 来翻墙的，但是它不能代理 udp，只有有限设备翻墙时是不是用 udp 没关系，但是，家里有很多设备，有些设备只能用 udp。考虑过 socks + tls，感觉也不太放心，要额外开 udp 443 这样的奇怪端口。有点儿不打自招的感觉。最后，选了 trojan，本质上它也是尽量的模仿了原生 https。trojan 还有两个版本，用的是 trojan-go，单纯因为不想搞一波依赖。再就是 Go 熟悉一些。

trojan-go 有个特点，它要求有个真的能访问的 http 服务器，于是用最简单的 python 的 http.server 来搞了，python2 的时候应该叫 simplehttp。`python3 -m http.server 80` 即可。还可以加 `--directory` 指定一个目录。

再就是 trojan-go 要求客户端填写 sni，也就是 key 申请的时候使用的域名，所以，这一切的前置步骤还是得去把[这里](https://github.com/haoel/haoel.github.io) 的域名申请、let's entcrypt 证书申请，包括 crontab 都配齐。有点儿门槛，我之前做过所以就省略了。

客户端部分直接用 clash，参考[这里](https://github.com/Dreamacro/clash/wiki/configuration) 就好了。
