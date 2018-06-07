---
title:  "如何配置 CentOS 6 NFS 服务"
date: 2014-06-05T22:21:06+08:00
---

# 服务器端

1. 关闭 SeLinux `vi /etc/selinux/config`
    ```text
    #SELINUX=enforcing #注释
    #SELINUXTYPE=targeted #注释掉
    SELINUX=disabled #增加
    ```
    `reboot #重启系统`
1. 用 root 用户建一个文件夹，就叫 /nfs 即可（注意，这里最好先 df 一下，看看哪个分区空间大，不一定就是/的空间最大，有些自动分区是/home空间最大）；
1. `yum -y install nfs-utils rpcbind`
1. `chkconfig nfs on ; chkconfig rpcbind on ; chkconfig nfslock on`
1. `vi /etc/exports` 加入 `/home/nfs 192.168.1.0/24(rw,sync,no_all_squash)`
1. `service rpcbind start ; service nfs start ; service nfslock star ; exportfs -a`
1. `vi /etc/sysconfig/nfs` 去掉下列前面的注释:
     ```text
     LOCKD_TCPPORT=32803
     LOCKD_UDPPORT=32769
     MOUNTD_PORT=892
     ```
1. `service rpcbind restart ; service nfs restart ; service nfslock restart`
1. `rpcinfo -p localhost` 记下端口和端口类型
1. `iptables -I INPUT -m state --state NEW -p tcp -m multiport --dport 111,892,2049,32803 -s 192.168.0.0/24 -j ACCEPT ; iptables -I INPUT -m state --state NEW -p udp -m multiport --dport 111,892,2049,32769 -s 192.168.0.0/24 -j ACCEPT` 自己根据ip段改一下。
1. 在客户端侧测试，如果通了，则 `service iptables save`

# 客户端

1. `mkdir /nfs`
1. `rpcinfo -p server的ip`
1. `showmount -e server的ip`
1. `mount -t nfs -o soft,intr,bg,rw server的ip:/home/nfs /nfs`
1. 解除挂载umount /nfs
1. 自动挂载`vi /etc/fstab`
    ```text
    server的ip:/home/nfs /nfs nfs soft,intr,bg,rw 0 0
    ```
