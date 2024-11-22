---
title: "How to Use HAProxy to Test CockroachDB"
date: 2018-07-10T15:07:00+08:00
---

## Installing HAProxy

`yum install haproxy` is effective for CentOS 7. After installation, you can start the service using `systemctl start haproxy`. But don't rush yet.

## Configuring HAProxy

Add the following content to /etc/haproxy/haproxy.cfg.

```bash
global # The content of global is generally fixed and quite understandable.
        log 127.0.0.1   local2
        maxconn 4096
        user haproxy
        group haproxy
        chroot /var/lib/haproxy
        daemon
        pidfile /var/run/haproxy.pid
        stats socket /var/run/haproxy.sock         # Create a socket file for haproxy
        nbproc 40                                  # Start 40 processes to forward concurrently, higher versions can use nbthread, a threaded approach.

defaults # This section is mostly copied, not entirely clear on the options.
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

listen cdb_cluster 0.0.0.0:3030  # The actual proxy name and address for receiving services.
## cdb balance leastconn - the cluster listening on port 3030.
        mode tcp
        balance leastconn  # This method is most suitable for databases; do not change.
        server cdb1 172.16.30.3:26257 check # Check seems to require a port for feedback status; without it, it might not work, but it doesn't matter.
        server cdb2 172.16.30.3:26258 check
        server cdb3 172.16.30.3:26259 check
        server cdb4 172.16.30.3:26260 check
```

## Start and Connect

`systemctl start haproxy` to start the service.

`psql -Uroot -h127.0.0.1 -p3030 test` to connect to the database.

## CockroachDB Official Recommendation

CockroachDB officially provided their recommended [configuration](https://www.cockroachlabs.com/docs/stable/deploy-cockroachdb-on-premises.html). In this configuration, they use:

```shell
default
# TCP keep-alive on client side. Server already enables them.
    option              clitcpka

listen psql
    option httpchk GET /health?ready=1
```

These two configurations, the first is to keep the client connection alive, which seems very useful. The second is a status check port, which I understand might be an option to ensure the service is available before dispatching requests, and it also seems very useful. It is recommended to add them.
