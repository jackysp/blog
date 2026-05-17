---
title: "How to Implement a Simple Load Using Sysbench"
slug: "how-to-implement-a-simple-load-using-sysbench"
tags: ['sysbench', 'benchmark']
date: 2020-12-14T12:06:00+08:00
draft: false
---

[Sysbench](https://github.com/akopytov/sysbench) is a tool commonly used in database testing. Since version 1.0, it has supported more powerful custom functions, allowing users to conveniently write some Lua scripts to simulate load. The purpose of writing this article is, firstly, because I wanted to explore Sysbench's custom load usage. Secondly, because I tried the mysqlslap tool provided by MySQL's official source, and found that it freezes easily during database performance testing, which could mislead users into thinking there is an issue with the database, causing trouble for many. Therefore, I want to help people avoid these pitfalls.

## A Simple Example

```lua
#!/usr/bin/env sysbench

require("oltp_common")

function prepare_statements()
end

function event()
    con:query("set autocommit = 1")
end
```

The first line `require` includes Sysbench's built-in basic library; the empty `prepare_statement` is a callback function from `oltp_common` that must be present; the specific execution of a single load is implemented in the `event` function.

Save this script as a Lua file, for example, named set.lua, and then execute it using sysbench.

```shell
sysbench --config-file=config --threads=100 set.lua --tables=1 --table_size=1000000 run
```

You can use the above command. Of course, here `--tables=1` and `--table_size=1000000` are not useful for this load, so they are optional. `--threads` controls concurrency.

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

In the config file, parameters you don't frequently adjust are written once to avoid having a long string of parameters in the command line. These are required fields: `time` represents the test duration, `report-interval` is used to observe real-time performance results, and the others pertain to how to connect to the database.

The running output generally looks like:

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

Finally, there will be a summary report.

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
