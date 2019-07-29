---
title: "如何使用 HAProxy 测试 CockroachDB"
date: 2018-07-10T15:07:00+08:00
---

## 安装 HAProxy

`yum install haproxy` 对 CentOS 7 有效。安装之后，即可使用 `systemctl start haproxy` 来启动服务了。但是先别急。

## 配置 HAProxy

在 /etc/haproxy/haproxy.cfg 里写入以下内容。

```bash
global # global 的内容基本固定，也比较好理解。
        log 127.0.0.1   local2
        maxconn 4096
        user haproxy
        group haproxy
        chroot /var/lib/haproxy
        daemon
        pidfile /var/run/haproxy.pid
        stats socket /var/run/haproxy.sock         # Make sock file for haproxy
        nbproc 40                                  # 启动 40 个进程并发转发，高版本可以用 nbthread，改为线程化。

defaults # 这部分都是抄的，option 不是很明白。
        log     global
        mode    http
        option  tcplog
        option  dontlognull
        retries 3
        option  redispatch
        maxconn 1024
        timeout connect 5000ms
        timeout client 50000ms
        timeout server 50000ms

listen cdb_cluster 0.0.0.0:3030  # 真正的 proxy 名以及接受服务的地址。
## cdb balance leastconn - the cluster listening on port 3030.
        mode tcp
        balance leastconn  # 这个方法最适用于数据库，不要改。
        server cdb1 172.16.30.3:26257 check # check 似乎可以接一个反馈状态的端口，不接可能不生效，但是无所谓。
        server cdb2 172.16.30.3:26258 check
        server cdb3 172.16.30.3:26259 check
        server cdb4 172.16.30.3:26260 check
```

## 启动、连接

`systemctl start haproxy` 启动服务。

`psql -Uroot -h127.0.0.1 -p3030 test` 连接数据库。

## CockroachDB 官方推荐

CockroachDB 官方给了自己推荐的[配置](https://www.cockroachlabs.com/docs/stable/deploy-cockroachdb-on-premises.html)。在这个配置里，它用了：

```shell
default
# TCP keep-alive on client side. Server already enables them.
    option              clitcpka

listen psql
    option httpchk GET /health?ready=1
```

这两个配置，第一个是让客户端 keep alive，感觉很有用。第二个是一个状态检查端口，我理解可能是确保服务可用再分发请求的一个选项，感觉也很有用。推荐加上。
