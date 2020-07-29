---
title:  "如何阅读 TiDB 的源代码（三）"
date: 2020-07-28T11:47:00+08:00
---

在上一篇中，给大家介绍了查看语法和查看配置的方法，本篇将介绍查看系统变量，包括，默认值、作用域，以及监控 metric 的方法。

## 系统变量

TiDB 的系统变量名定义在 [tidb_vars.go](https://github.com/pingcap/tidb/blob/db0310b17901b1a59f7f728294455ed9667f88ac/sessionctx/variable/tidb_vars.go) 中，
其中也包含了一些变量的默认值，但实际将他们组合在一起的位置是 [defaultSysVars](https://github.com/pingcap/tidb/blob/12aac547a9068c404ad18093ae4d0ea4d060a465/sessionctx/variable/sysvar.go#L96)

![defaultSysVars](/posts/images/20200728151254.png)

这个大的 struct 数组定义了 TiDB 中所有变量的作用域、变量名和默认值。这里面除了 TiDB 自己独有的系统变量以外，同时，也兼容了 MySQL 的系统变量。

### 作用域

TiDB 中，从字面意思上讲，有三种变量作用域，

![defaultSysVars](/posts/images/20200728151833.png)

分别是 ScopeNone、ScopeGlobal 和 ScopeSession。它们分别代表，

* ScopeNone：只读变量
* ScopeGlobal：全局变量
* ScopeSession：会话变量

这三个作用域的实际作用是，在使用 SQL 实际去读写它们时，会要求使用相应的语法，如果 SQL 报错失败，SQL 作用必然是没有生效，如果 SQL 执行成功，仅意味着能设置完成，并不意味着实际按照对应的作用域生效。

下面我们用第一篇里提到的方法来启动一个单机版的 TiDB 来进行演示：

#### ScopeNone

以 `performance_schema_max_mutex_classes` 为例，

    MySQL  127.0.0.1:4000  SQL > select @@performance_schema_max_mutex_classes;
    +----------------------------------------+
    | @@performance_schema_max_mutex_classes |
    +----------------------------------------+
    | 200                                    |
    +----------------------------------------+
    1 row in set (0.0002 sec)
    MySQL  127.0.0.1:4000  SQL > select @@global.performance_schema_max_mutex_classes;
    +-----------------------------------------------+
    | @@global.performance_schema_max_mutex_classes |
    +-----------------------------------------------+
    | 200                                           |
    +-----------------------------------------------+
    1 row in set (0.0004 sec)
    MySQL  127.0.0.1:4000  SQL > select @@session.performance_schema_max_mutex_classes;
    ERROR: 1238 (HY000): Variable 'performance_schema_max_mutex_classes' is a GLOBAL variable


可以看到，ScopeNone 的作用域可以按照全局变量来读，

    MySQL  127.0.0.1:4000  SQL > set global performance_schema_max_mutex_classes = 1;
    ERROR: 1105 (HY000): Variable 'performance_schema_max_mutex_classes' is a read only variable
    MySQL  127.0.0.1:4000  SQL > set performance_schema_max_mutex_classes = 1;
    ERROR: 1105 (HY000): Variable 'performance_schema_max_mutex_classes' is a read only variable
    MySQL  127.0.0.1:4000  SQL > set session performance_schema_max_mutex_classes = 1;
    ERROR: 1105 (HY000): Variable 'performance_schema_max_mutex_classes' is a read only variable

但是，无论哪种方式都无法写。

实际上，追踪 ScopeNone 的使用，可以看到

![defaultSysVars](/posts/images/20200728155134.png)

在 `setSysVariable` 里遇到这种作用域的变量，会直接返回错误。

![defaultSysVars](/posts/images/20200728155332.png)

在 `ValidateGetSystemVar` 里把它按照 ScopeGlobal 来一同处理了。
从原理上讲，这种 ScopeNone 的变量，实际就是只有代码里的一份，TiDB 启动后就是存在内存中的一块只读内存，不会实际存储在 TiKV。

#### ScopeGlobal

以 `gtid_mode` 为例，

    MySQL  127.0.0.1:4000  SQL > select @@gtid_mode;
    +-------------+
    | @@gtid_mode |
    +-------------+
    | OFF         |
    +-------------+
    1 row in set (0.0003 sec)
    MySQL  127.0.0.1:4000  SQL > select @@global.gtid_mode;
    +--------------------+
    | @@global.gtid_mode |
    +--------------------+
    | OFF                |
    +--------------------+
    1 row in set (0.0006 sec)
    MySQL  127.0.0.1:4000  SQL > select @@session.gtid_mode;
    ERROR: 1238 (HY000): Variable 'gtid_mode' is a GLOBAL variable

就是与 MySQL 兼容的全局变量读取方式，

    MySQL  127.0.0.1:4000  SQL > set gtid_mode=on;
    ERROR: 1105 (HY000): Variable 'gtid_mode' is a GLOBAL variable and should be set with SET GLOBAL
    MySQL  127.0.0.1:4000  SQL > set session gtid_mode=on;
    ERROR: 1105 (HY000): Variable 'gtid_mode' is a GLOBAL variable and should be set with SET GLOBAL
    MySQL  127.0.0.1:4000  SQL > set global gtid_mode=on;
    Query OK, 0 rows affected (0.0029 sec)
    MySQL  127.0.0.1:4000  SQL > select @@global.gtid_mode;
    +--------------------+
    | @@global.gtid_mode |
    +--------------------+
    | ON                 |
    +--------------------+
    1 row in set (0.0005 sec)
    MySQL  127.0.0.1:4000  SQL > select @@gtid_mode;
    +-------------+
    | @@gtid_mode |
    +-------------+
    | ON          |
    +-------------+
    1 row in set (0.0006 sec)

设置方法，也跟 MySQL 兼容。这时候，我们可以关掉单机 TiDB，然后，再次启动，

    MySQL  127.0.0.1:4000  SQL > select @@gtid_mode;
    +-------------+
    | @@gtid_mode |
    +-------------+
    | ON          |
    +-------------+
    1 row in set (0.0003 sec)

可以看到，依旧能读到这个结果，也就是这种设置，是存储到了存储引擎里，持久化了的。
仔细看代码可以看到，

![defaultSysVars](/posts/images/20200728164505.png)

实际实现上是执行了一个内部的 replace 语句来更新了原有值。这里是一个完整的事务，会经历获取两次 tso、提交整个过程，相对于设置会话变量要慢。

#### ScopeSession

以 `rand_seed2` 为例，

    MySQL  127.0.0.1:4000  SQL > select @@rand_seed2;
    +--------------+
    | @@rand_seed2 |
    +--------------+
    |              |
    +--------------+
    1 row in set (0.0005 sec)
    MySQL  127.0.0.1:4000  SQL > select @@session.rand_seed2;
    +----------------------+
    | @@session.rand_seed2 |
    +----------------------+
    |                      |
    +----------------------+
    1 row in set (0.0003 sec)
    MySQL  127.0.0.1:4000  SQL > select @@global.rand_seed2;
    ERROR: 1238 (HY000): Variable 'rand_seed2' is a SESSION variable

读取是兼容 MySQL 的

    MySQL  127.0.0.1:4000  SQL > set rand_seed2='abc';
    Query OK, 0 rows affected (0.0006 sec)
    MySQL  127.0.0.1:4000  SQL > set session rand_seed2='bcd';
    Query OK, 0 rows affected (0.0004 sec)
    MySQL  127.0.0.1:4000  SQL > set global rand_seed2='cde';
    ERROR: 1105 (HY000): Variable 'rand_seed2' is a SESSION variable and can't be used with SET GLOBAL
    MySQL  127.0.0.1:4000  SQL > select @@rand_seed2;
    +--------------+
    | @@rand_seed2 |
    +--------------+
    | bcd          |
    +--------------+

设置也是，其实可以简单看到，该操作内部仅仅是对会话的内存做了设置。
实际最终生效的位置是 [SetSystemVar](https://github.com/pingcap/tidb/blob/f360ad7a434e4edd4d7ebce5ed5dc2b9826b6ed0/sessionctx/variable/session.go#L998)

![defaultSysVars](/posts/images/20200728171914.png)

这里就会有几分 trick 的地方了。

### 变量实际作用范围

上一节讲到了会话变量的设置，基于 MySQL 的变量规则，设置全局变量不影响当前会话，只有初始创建的会话，才会重新获取全局变量为会话变量赋值。
最终实际起作用的还是会话变量。对于纯粹的全局变量也就是没有会话变量属性的，其生效方式也有其自己的特点，本章节将介绍：

1. 会话变量的生效方式
1. 纯粹全局变量的生效方式
1. 全局变量的作用机制

三个方面的内容。

#### 会话变量的生效方式

不管会话变量是不是同时也是全局变量，其差别仅仅在于，在会话启动的时候，是否需要从存储引擎载入全局变量数据，不需要载入的代码中的默认值就是其永久的初始值。

具体变量是在多大范围起作用，只能在 [SetSystemVar](https://github.com/pingcap/tidb/blob/f360ad7a434e4edd4d7ebce5ed5dc2b9826b6ed0/sessionctx/variable/session.go#L998) 里查看。

![defaultSysVars](/posts/images/20200728173351.png)

比如，这一部分，`s.MemQuotaNestedLoopApply = tidbOptInt64(val, DefTiDBMemQuotaNestedLoopApply)` 这里 s 是当前会话的变量结构体，对它改变，其作用就是对当前会话进行改变，

像是，`atomic.StoreUint32(&ProcessGeneralLog, uint32(tidbOptPositiveInt32(val, DefTiDBGeneralLog)))` 其实际是修改了 `ProcessGeneralLog` 这个全局变量的值，也就是 `set tidb_general_log = 1` 是直接对当前整个 TiDB 生效的。

#### 纯粹全局变量的生效方式

当前 TiDB 内存粹的全局变量都是为一些后台线程服务的，比如，DDL、统计信息等等。

![defaultSysVars](/posts/images/20200728174207.png)
![defaultSysVars](/posts/images/20200728174243.png)

因为它们都是只有一个 TiDB server 才需要使用的，会话层级本身对它也没有意义。

#### 全局变量的作用机制

TiDB 的全局变量不会在设置之后立刻生效，因为每建立一次连接，连接都会先从 TiKV 获取最新的全局系统变量来赋值给当前会话，当大量连接并发创建时，会对 TiKV 中存储这个少量全局变量的节点进行频繁访问，因此，TiDB 内部缓存了全局变量，每两秒钟会进行一次更新，这样就能极大的降低 TiKV 的压力。
带来的问题是，在设置全局变量后，需要等待一下再开始创建新连接，这样来保证新连接一定能读到最新的全局变量。这是 TiDB 中为数不多的数据最终一致的地方。

具体的可以看 `loadCommonGlobalVariablesIfNeeded` 中的[这段注释](https://github.com/pingcap/tidb/blob/838b6a0cf2df2d1907508e56d9de9ba7fab502e5/session/session.go#L1990)。

![defaultSysVars](/posts/images/20200728191527.png)

## Metrics

相对于系统变量，TiDB 中的 Metrics 比较简单，或者说单纯，最常用的 Metrics 是 Histogram 和 Counter，一个用来记录当次操作的实际取值，另一个用来记录固定事件的发生次数。
TiDB 中的 Metrics 都被统一的放到了[这里](https://github.com/pingcap/tidb/tree/cbc225fa17c93a3f58bef41b5accb57beb0d9586/metrics)，其中 alertmanager 和 grafana 分别还放了 AlertManager 和 Grafana 的脚本。

Metrics 有很多，个人认为，从入手角度看，拿一个具体监控来讲比较好。我们就以 TPS 面板为例来讲好了。

![tps](/posts/images/20200729205545.png)

点开 EDIT，可以看到监控公式是

    sum(rate(tidb_session_transaction_duration_seconds_count[1m])) by (type, txn_mode)

这里面 `tidb_session_transaction_duration_seconds` 是这个具体 Metrics 的名字，由于它是一个 Histogram，所以，实际可以表达为三种值，
sum、count 和 bucket，分别代表记录取值总数、次数（作用与 Counter 相同）和按桶分布。

![tps](/posts/images/20200729210124.png)

在这里 [1m] 代表时间窗为 1 分钟，代表取值粒度，rate 为计算斜率，也就是变量的增长率，也就是转化为每秒发生多少次，sum 代表加和，与最后的 by (type, txn_mode) 结合代表，按 type 和 txn_mode 两个维度加和。

下面的 Legend 为图例展示 {{type}}-{{txn_mode}} 上面的维度用 {{}} 围起来之后就能展示其真实 label 名字。

![tps](/posts/images/20200729210541.png)

也就变成了这样。也就是说，事务最终状态一共有三种，用户主动提交并且成功了是 commit，用户主动回滚是 rollback（回滚不会失败），用户主动提交，但是失败了是 abort。

第二个标签是 txn_mode，有两个，分别代表乐观事务和悲观事务，这里就没啥好解释的了。

对应到代码里呢，

![tps](/posts/images/20200729211352.png)

是这段代码，可以看到，`tidb_session_transaction_duration_seconds` 被拆成了好几段，分了 namespace 和 subsystem，也就是一般看到一个长
`tidb_session_transaction_duration_seconds_count` 这样的公式里的变量，要去掉头上两个词，和尾部最后一个词，才能在 TiDB 代码里找到。

从这个代码片段里可以看到，它是一个 Histogram，而且是多个 HistogramVec，也就是一个直方图数组，因为，它同时记录了多个不同 label 的数据。
LbTxnMode、LblType 就是这两个 label。

看它的引用可以看到，有一个注册的地方，就是第一篇我们讲的 main 函数注册 Metrics 的地方。

![tps](/posts/images/20200729211511.png)

其他的引用就是讲 Metrics 实例化，为什么要这么做呢？主要是随着 label 的增多，Metrics 的性能会越来越差，这跟 Prometheus 的实现有关，不得已我们才做了很多实例化的全局变量。

![tps](/posts/images/20200729211725.png)

以 Rollback 这个实现为例，其本质就是在真是执行 Rollback 时，将事务实际执行时间记录了下来，由于是 Histogram，同时在本例里当作了计数器来用。

![tps](/posts/images/20200729211935.png)
