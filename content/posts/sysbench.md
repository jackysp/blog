---
title:  "如何用 Sysbench 实现简单负载"
date: 2020-12-14T12:06:00+08:00
draft: true
---

[Sysbench](https://github.com/akopytov/sysbench) 是数据库测试中常使用的工具。1.0 版本以后，它支持了更强大的自定义功能。可以让使用者方便的编写一些 lua 脚本来模拟负载。
写这篇文章的目的，一是本来就想研究下 Sysbench 自定义负载的用法，二是，因为看到了 MySQL 官方给出的 mysqlslap 工具，试用了一下，发现随随便便就 hang 死在那，在数据库性能测试中，
会让用户误认为是数据库有问题，坑了不少人，所以，想让大家少踩坑吧。

## 一个简单的例子

```lua
#!/usr/bin/env sysbench

require("oltp_common")

function prepare_statements()
end

function event()
    con:query("set autocommit = 1")
end
```

第一行 `require` 将 Sysbench 自带的基础库包含进来；
空的 `prepare_statement` 是 `oltp_common` 的回调函数，必须要有；
具体单次负载如何执行就是后面的 `event` 函数里实现了。

把这段脚本保存为一个 lua 文件，比如叫 set.lua，然后用 sysbench 执行它就可以了。

```shell
sysbench --config-file=config --threads=100 set.lua --tables=1 --table_size=1000000 run
```

比如用上述命令。当然这里 `--tables=1` 和 `--table_size=1000000` 对于这个负载都是没什么用的，不填也行，`--threads` 控制并发度。

```shell
$ cat config
time=120
db-driver=mysql
mysql-host=172.16.5.33
mysql-port=34000
mysql-user=root
mysql-db=sbtest
report-interval=10
```

config 文件里就是把不常调整的参数一次性写进去，避免命令行里一长串参数。这些都是必填项目，`time` 代表测试时长，`report-interval` 用来观测实时性能结果，
其他的都是如何连接数据库。

跑起来的样子基本就是：

```text
[ 10s ] thds: 100 tps: 94574.34 qps: 94574.34 (r/w/o: 0.00/0.00/94574.34) lat (ms,95%): 3.68 err/s: 0.00 reconn/s: 0.00
[ 20s ] thds: 100 tps: 77720.30 qps: 77720.30 (r/w/o: 0.00/0.00/77720.30) lat (ms,95%): 5.28 err/s: 0.00 reconn/s: 0.00
[ 30s ] thds: 100 tps: 56080.10 qps: 56080.10 (r/w/o: 0.00/0.00/56080.10) lat (ms,95%): 9.22 err/s: 0.00 reconn/s: 0.00
[ 40s ] thds: 100 tps: 93315.90 qps: 93315.90 (r/w/o: 0.00/0.00/93315.90) lat (ms,95%): 4.82 err/s: 0.00 reconn/s: 0.00
[ 50s ] thds: 100 tps: 97491.02 qps: 97491.02 (r/w/o: 0.00/0.00/97491.02) lat (ms,95%): 4.65 err/s: 0.00 reconn/s: 0.00
[ 60s ] thds: 100 tps: 94034.27 qps: 94034.27 (r/w/o: 0.00/0.00/94034.27) lat (ms,95%): 4.91 err/s: 0.00 reconn/s: 0.00
[ 70s ] thds: 100 tps: 74707.37 qps: 74707.37 (r/w/o: 0.00/0.00/74707.37) lat (ms,95%): 6.79 err/s: 0.00 reconn/s: 0.00
[ 80s ] thds: 100 tps: 89485.10 qps: 89485.10 (r/w/o: 0.00/0.00/89485.10) lat (ms,95%): 5.18 err/s: 0.00 reconn/s: 0.00
[ 90s ] thds: 100 tps: 109296.44 qps: 109296.44 (r/w/o: 0.00/0.00/109296.44) lat (ms,95%): 2.91 err/s: 0.00 reconn/s: 0.00
```

最后，结束还会有个汇总报告。

```text
SQL statistics:
    queries performed:
        read:                            0
        write:                           0
        other:                           10424012
        total:                           10424012
    transactions:                        10424012 (86855.65 per sec.)
    queries:                             10424012 (86855.65 per sec.)
    ignored errors:                      0      (0.00 per sec.)
    reconnects:                          0      (0.00 per sec.)

Throughput:
    events/s (eps):                      86855.6517
    time elapsed:                        120.0154s
    total number of events:              10424012

Latency (ms):
         min:                                    0.09
         avg:                                    1.15
         max:                                 1527.74
         95th percentile:                        4.91
         sum:                             11994122.49

Threads fairness:
    events (avg/stddev):           104240.1200/600.21
    execution time (avg/stddev):   119.9412/0.01
```
