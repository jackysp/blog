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

    ```SQL
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
    ```

可以看到，ScopeNone 的作用域可以按照全局变量来读，

    ```SQL
    MySQL  127.0.0.1:4000  SQL > set global performance_schema_max_mutex_classes = 1;
    ERROR: 1105 (HY000): Variable 'performance_schema_max_mutex_classes' is a read only variable
    MySQL  127.0.0.1:4000  SQL > set performance_schema_max_mutex_classes = 1;
    ERROR: 1105 (HY000): Variable 'performance_schema_max_mutex_classes' is a read only variable
    MySQL  127.0.0.1:4000  SQL > set session performance_schema_max_mutex_classes = 1;
    ERROR: 1105 (HY000): Variable 'performance_schema_max_mutex_classes' is a read only variable
    ```

但是，无论哪种方式都无法写。

实际上，追踪 ScopeNone 的使用，可以看到

    ![defaultSysVars](/posts/images/20200728155134.png)

在 `setSysVariable` 里遇到这种作用域的变量，会直接返回错误。

    ![defaultSysVars](/posts/images/20200728155332.png)

在 `ValidateGetSystemVar` 里把它按照 ScopeGlobal 来一同处理了。
从原理上讲，这种 ScopeNone 的变量，实际就是只有代码里的一份，TiDB 启动后就是存在内存中的一块只读内存，不会实际存储在 TiKV。

#### ScopeGlobal

以 `gtid_mode` 为例，

    ```SQL
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
    ```

就是与 MySQL 兼容的全局变量读取方式，

    ```SQL
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
    ```

设置方法，也跟 MySQL 兼容。这时候，我们可以关掉单机 TiDB，然后，再次启动，

    ```SQL
    MySQL  127.0.0.1:4000  SQL > select @@gtid_mode;
    +-------------+
    | @@gtid_mode |
    +-------------+
    | ON          |
    +-------------+
    1 row in set (0.0003 sec)
    ```

可以看到，依旧能读到这个结果，也就是这种设置，是存储到了存储引擎里，持久化了的。
仔细看代码可以看到，

    ![defaultSysVars](/posts/images/20200728164505.png)

实际实现上是执行了一个内部的 replace 语句来更新了原有值。这里是一个完整的事务，会经历获取两次 tso、提交整个过程，相对于设置会话变量要慢。

#### ScopeSession

以 `rand_seed2` 为例，

    ```SQL
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
    ```

读取是兼容 MySQL 的

    ```SQL
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
    ```

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
