---
title: "How to Deploy a Secure Transparent Gateway"
slug: "how-to-deploy-a-secure-transparent-gateway"
tags: ['networking', 'gateway']
date: 2022-10-12T21:07:00+08:00
draft: false
---

## Background

After moving house, there are many more devices at home that need internet access. However, I don't want to configure a proxy on each device, so I thought of using a transparent gateway.

## Transparent Gateway

After some research, I found that the easiest way is to use the premium version of Clash, although I didn't know when Clash released a premium version. I mainly referred to [this article](https://www.cfmem.com/2022/05/clash.html). It's much simpler than setting up iptables.

### Network Topology

I have a 10-year-old Thinkpad x230 at home, which is perfect for this purpose. Here is a simple topology diagram.

Router1 is a fiber-optic modem with routing capabilities, Router2 is a regular router, with the gateway and DNS pointing to the Thinkpad, where Linux is running to act as a transparent gateway with Clash on top.

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

### Add DNS Section in Clash Configuration

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

### Clash tun Feature Section

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

For traffic forwarding, simply edit `/etc/sysctl.conf` on the Thinkpad and add `net.ipv4.ip_forward=1`, then execute `sysctl -p` to apply it. After that, point the gateway and DNS of Router2 to the Thinkpad, and you're done.

## Network Protocols

Initially, I used native HTTP2 for unblocking, but it cannot proxy UDP. When only a few devices need unblocking, it doesn't matter whether UDP is used, but with many devices at home, some of them can only use UDP. I considered socks + tls, but it didn't feel secure and required opening odd ports like UDP 443. It felt like giving away my intentions. Eventually, I chose Trojan, which essentially mimics native HTTPS. Trojan has two versions; I used Trojan-go simply because I didn't want to manage dependencies. Also, I'm more familiar with Go.

Trojan-go has a requirement for a genuinely accessible HTTP server, so I used the simplest Python `http.server`. Back in Python 2, it was called `simplehttp`. You can simply use `python3 -m http.server 80` and optionally add `--directory` to specify a directory.

Additionally, Trojan-go requires the client to fill in the SNI, which means using the domain used during key application. Therefore, prerequisites like applying for the [domain](https://github.com/haoel/haoel.github.io), applying for Let's Encrypt certificates, and configuring crontab must all be completed. There's a learning curve, but I had done it before, so I just skipped that part.

For the client part, you can use Clash directly, and refer to [here](https://github.com/Dreamacro/clash/wiki/configuration) for guidance.
