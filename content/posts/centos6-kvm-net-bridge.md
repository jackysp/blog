---
title: "如何配置 CentOS KVM 网络桥接模式"
date: 2014-06-05T22:21:06+08:00
---

# 什么是桥接

高度模拟网卡，让路由认为虚拟机的网卡是真实存在的，个人感觉类似电阻的并联，而 NAT （另一种常用的虚拟机网络连接方式）更像寄生在 host 网卡的形式。

# 为什么用桥接

能把虚拟机当作完全独立的机器来操作，可以与外网互相访问（ NAT 不行）。

# 怎么桥接

在 CentOS 6 下参考[这篇文章](http://www.techotopia.com/index.php/Creating_a_CentOS_6_KVM_Networked_Bridge_Interface)
里的命令行方式。

不采用 GUI 的方式是因为：

* 不知道最后一个图填哪几个选项；
* 不知道如果选错了怎么重置。

命令行形式：

1. `rpm -q bridge-utils`
    一般这个都已经装了，没有的话如下 `su -; yum install bridge-utils`

1. ifconfig 至少应该有三个网络
    ```text
     eth0      Link encap:Ethernet  HWaddr 00:18:E7:16:DA:65
               inet addr:192.168.0.117  Bcast:192.168.0.255  Mask:255.255.255.0
               inet6 addr: fe80::218:e7ff:fe16:da65/64 Scope:Link
               UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
               RX packets:556 errors:0 dropped:0 overruns:0 frame:0
               TX packets:414 errors:0 dropped:0 overruns:0 carrier:0
               collisions:0 txqueuelen:1000
               RX bytes:222834 (217.6 KiB)  TX bytes:48430 (47.2 KiB)
               Interrupt:16 Base address:0x4f00

     lo        Link encap:Local Loopback
               inet addr:127.0.0.1  Mask:255.0.0.0
               inet6 addr: ::1/128 Scope:Host
               UP LOOPBACK RUNNING  MTU:16436  Metric:1
               RX packets:8 errors:0 dropped:0 overruns:0 frame:0
               TX packets:8 errors:0 dropped:0 overruns:0 carrier:0
               collisions:0 txqueuelen:0
               RX bytes:480 (480.0 b)  TX bytes:480 (480.0 b)

     virbr0    Link encap:Ethernet  HWaddr 52:54:00:2A:C1:7E
               inet addr:192.168.122.1  Bcast:192.168.122.255  Mask:255.255.255.0
               UP BROADCAST RUNNING MULTICAST  MTU:1500  Metric:1
               RX packets:0 errors:0 dropped:0 overruns:0 frame:0
               TX packets:13 errors:0 dropped:0 overruns:0 carrier:0
               collisions:0 txqueuelen:0
               RX bytes:0 (0.0 b)  TX bytes:2793 (2.7 KiB)
    ```
1. `su – ;cd /etc/sysconfig/network-scripts`
1. `ifdown eth0`
    这一步一定要做，所以必须要本机配置，本人在第一次配置的时候没有先关网络（因为要远程），结果我没想到在网络没有重启的情况下ifcfg-eth0的配置就更新了，然后网络就再也连不上了。
1. 在 ifcfg-eth0 里填
    ```text
     DEVICE=eth0
     ONBOOT=yes
     BRIDGE=br0
    ```
    文件里只保留这三行就行，不用配置 ip，桥接貌似是用桥接器代替原始网卡，所以配置部分交给桥接器就可以了。
1. 新建文件 ifcfg-br0，
    ```text
     DEVICE=br0
     ONBOOT=yes
     TYPE=Bridge
     BOOTPROTO=static
     IPADDR=xxx.xxx.xxx.xxx （这里ip等配置就是你原来填在ifcfg-eth0里的）
     GATEWAY=xxx.xxx.xxx.xxx
     ...（不再列举，下两行也要写，不过不知道是什么）
     STP=on
     DELAY=0
    ```
1. `ifup br0; ifup eth0`
1. 看下 `ifconfig` ，应该就有 br0 了，
1. 编辑 /etc/sysconfig/iptables 加入，
    `-INPUT -i br0 -j ACCEPT （大概是这样，需要根据实际情况修改）`
1. `service iptables restart`
1. 用 virt-manager 新建虚拟机的时候就可以选 br0 了，否则桥接没法选。

**注意：** 配置虚拟机内的 ip 时要注意指定 GATEWAY ，否则只能访问内网，不能访问外网。也就是这时候虚拟机不会自动找 GATEWAY 了。
