---
title: "How to Read TiDB Source Code (Part 3)"
slug: "how-to-read-tidb-source-code-part-3"
tags: ['tidb', 'database', 'source-code']
date: 2020-07-28T11:47:00+08:00
draft: false
---

In the previous article, we introduced methods for viewing syntax and configurations. In this article, we will discuss how to view system variables, including default values, scopes, and how to monitor metrics.

## System Variables

The system variable names in TiDB are defined in [tidb_vars.go](https://github.com/pingcap/tidb/blob/db0310b17901b1a59f7f728294455ed9667f88ac/sessionctx/variable/tidb_vars.go). This file also includes some default values for variables, but the place where they are actually assembled is [defaultSysVars](https://github.com/pingcap/tidb/blob/12aac547a9068c404ad18093ae4d0ea4d060a465/sessionctx/variable/sysvar.go#L96).

![defaultSysVars](/posts/images/20200728151254.webp)

This large struct array defines the scope, variable names, and default values for all variables in TiDB. Besides TiDB's own system variables, it also includes compatibility with MySQL's system variables.

### Scope

In TiDB, there are three types of variable scopes literally:

![defaultSysVars](/posts/images/20200728151833.webp)

They are ScopeNone, ScopeGlobal, and ScopeSession. They represent:

* ScopeNone: Read-only variables
* ScopeGlobal: Global variables
* ScopeSession: Session variables

The actual effect of these scopes is that when you use SQL to read or write them, you need to use the corresponding syntax. If the SQL fails, the SQL operation does not take effect. If the SQL executes successfully, it merely means the setting is complete, but it does not mean that it takes effect according to the corresponding scope.

Let's use the method mentioned in the first article to start a single-node TiDB for demonstration:

#### ScopeNone

Take `performance_schema_max_mutex_classes` as an example,

```sql
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

As you can see, the scope of ScopeNone can be read as a global variable,

```sql
MySQL  127.0.0.1:4000  SQL > set global performance_schema_max_mutex_classes = 1;
ERROR: 1105 (HY000): Variable 'performance_schema_max_mutex_classes' is a read-only variable
MySQL  127.0.0.1:4000  SQL > set performance_schema_max_mutex_classes = 1;
ERROR: 1105 (HY000): Variable 'performance_schema_max_mutex_classes' is a read-only variable
MySQL  127.0.0.1:4000  SQL > set session performance_schema_max_mutex_classes = 1;
ERROR: 1105 (HY000): Variable 'performance_schema_max_mutex_classes' is a read-only variable
```

But it cannot be set in any way.

To trace the usage of ScopeNone, you will see

![defaultSysVars](/posts/images/20200728155134.webp)

In `setSysVariable`, when this type of scope variable is encountered, an error is directly returned.

![defaultSysVars](/posts/images/20200728155332.webp)

In `ValidateGetSystemVar`, it is handled as a global variable.
From a theoretical standpoint, these ScopeNone variables are essentially a single copy in the code. Once TiDB is started, they exist in memory as read-only and are not actually stored in TiKV.

#### ScopeGlobal

Using `gtid_mode` as an example,

```sql
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

It works the same way as MySQL global variable reading,

```sql
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

The setting method is also compatible with MySQL. At this point, we can shut down the single-instance TiDB and restart it,

```sql
MySQL  127.0.0.1:4000  SQL > select @@gtid_mode;
+-------------+
| @@gtid_mode |
+-------------+
| ON          |
+-------------+
1 row in set (0.0003 sec)
```

And you can see that the result can still be read, meaning that this setting was persisted to the storage engine.
Looking closely at the code, you can see:

![defaultSysVars](/posts/images/20200728164505.webp)

The actual implementation involves executing an internal replace statement to update the original value. This constitutes a complete transaction involving acquiring two TSOs and committing the entire process, making it slower compared to setting session variables.

#### ScopeSession

Using `rand_seed2` as an example,

```sql
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

Reading is compatible with MySQL.

```sql
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

The setting is also compatible with MySQL. It can be simply observed that this operation only changes the session's memory.
The actual place where it finally takes effect is [SetSystemVar](https://github.com/pingcap/tidb/blob/f360ad7a434e4edd4d7ebce5ed5dc2b9826b6ed0/sessionctx/variable/session.go#L998).

![defaultSysVars](/posts/images/20200728171914.webp)

There are some tricks here.

### Actual Scope of Variables

The previous section covered setting session variables. Based on MySQL's variable rules, setting a global variable does not affect the current session. Only newly created sessions will load global variables for session variable assignment. Ultimately, the active session variable take effect. Global variables without session properties still have unique characteristics, and this chapter will cover:

1. Activation of session variables
1. Activation of pure global variables
1. Mechanism of global variable function

These three aspects.

#### Activation of Session Variables

Whether a session variable is also a global variable only affects whether it needs to load global variable data from the storage engine when the session starts. The default value in the code is the initial value for eternity if no loading is required.

The actual range where a variable operates can only be observed in [SetSystemVar](https://github.com/pingcap/tidb/blob/f360ad7a434e4edd4d7ebce5ed5dc2b9826b6ed0/sessionctx/variable/session.go#L998).

![defaultSysVars](/posts/images/20200728173351.webp)

For example, in this part, `s.MemQuotaNestedLoopApply = tidbOptInt64(val, DefTiDBMemQuotaNestedLoopApply)` changes the `s` structure, effectively changing the current session,

Whereas `atomic.StoreUint32(&ProcessGeneralLog, uint32(tidbOptPositiveInt32(val, DefTiDBGeneralLog)))` changes the value of the global variable `ProcessGeneralLog`, thereby affecting the entire TiDB instance when `set tidb_general_log = 1` is executed.

#### Activation of Pure Global Variables

Pure global variables in current TiDB are used for background threads like DDL, statistics, etc.

![defaultSysVars](/posts/images/20200728174207.webp)
![defaultSysVars](/posts/images/20200728174243.webp)

Because only one TiDB server requires them, session-level variables hold no meaning for these.

#### Mechanism of Global Variable Function

Global variables in TiDB don't activate immediately after setting. A connection fetches the latest global system variables from TiKV to assign them to the current session the first time it's established. Concurrent connection creation results in frequent access to the TiKV node holding a few global variables. Thus, TiDB caches global variables, updating them every two seconds, significantly reducing TiKV load.
The problem arises that after setting a global variable, a brief wait is necessary before creating a new connection, ensuring new connections will read the latest global variable. This is one of the few eventual consistency locations within TiDB.

For specific details, see [this commentary](https://github.com/pingcap/tidb/blob/838b6a0cf2df2d1907508e56d9de9ba7fab502e5/session/session.go#L1990) in `loadCommonGlobalVariablesIfNeeded`.

![defaultSysVars](/posts/images/20200728191527.webp)

## Metrics

Compared to system variables, Metrics in TiDB are simpler, or straightforward. The most common Metrics are Histogram and Counter, the former is used to record actual values for an operation and the latter records occurrences of fixed events.
All Metrics in TiDB are uniformly located [here](https://github.com/pingcap/tidb/tree/cbc225fa17c93a3f58bef41b5accb57beb0d9586/metrics), with AlertManager and Grafana scripts also available separately under alertmanager and grafana.

There are many Metrics, and from a beginner's perspective, it's best to focus on a specific monitoring example. Let's take the TPS (transactions per second) panel as an example.

![tps](/posts/images/20200729205545.webp)

Click EDIT and you will see the monitoring formula is:

![tps2](/posts/images/20200729210124.webp)

The `tidb_session_transaction_duration_seconds` is the name of this specific metric. Since it is a histogram, it can actually be expressed as three types of values: sum, count, and bucket, which represent the total sum of values, the count (which functions the same as a counter), and the distribution by bucket, respectively.

In this context, [1m] represents a time window of 1 minute, indicating the precision of the measurement. The rate function calculates the slope, essentially the rate of change, indicating how many times something occurs per second. The sum function is used for aggregation, and when combined with by (type, txn_mode), it represents aggregation by the dimensions of type and txn_mode.

The Legend below displays the dimensions above using {{type}}-{{txn_mode}}. When surrounded by {{}}, it can display the actual label names.

In this representation, the final states of transactions are commit, abort, and rollback. A commit indicates a successful user-initiated transaction, rollback indicates a user-initiated rollback (which cannot fail), and abort indicates a user-initiated commit that failed.

The second label, txn_mode, refers to two modes: optimistic and pessimistic transactions. There's nothing further to explain about these modes.

Corresponding to the code:

![alt text](/posts/images/20200729211352.webp)

This segment of code shows that `tidb_session_transaction_duration_seconds` is divided into several parts, including namespace and subsystem. Generally, to find a variable in a formula like `tidb_session_transaction_duration_seconds_count` within TiDB code, you need to remove the first two words and the last word.

From this code snippet, you can see it's a histogram, specifically a HistogramVec, which is an array of histograms because it records data with several different labels. The labels LblTxnMode and LblType are these two labels.

![alt text](/posts/images/20200729211511.webp)

Checking the references, there is a place for registration, which is in the main function we discussed in the first article, where metrics are registered.

![alt text](/posts/images/20200729211725.webp)

Other references show how metrics are instantiated. Why do we do this? Mainly because as the number of labels increases, the performance of metrics becomes poorer, which is related to Prometheus's implementation. We had no choice but to create many instantiated global variables.

![alt text](/posts/images/20200729211935.webp)

Taking the implementation of Rollback as an example, its essence is to record the actual execution time of a transaction when Rollback is truly executed. Since it’s a histogram, it is also used as a counter in this instance.
