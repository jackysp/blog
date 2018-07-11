---
title: "TiDB 的 INSERT 语句是如何实现的"
date: 2018-07-11T14:18:00+08:00
draft: false
---

在之前的一篇文章中[《Insert 语句概览》](https://zhuanlan.zhihu.com/p/34512827)中，已经介绍了 INSERT 语句的大体流程。在本篇中将详细介绍 TiDB 对于几种 INSERT 语句的的实现。

# INSERT 语句的种类

在 TiDB 中一共有以下几种 INSERT 语句：

* INSERT
* INSERT IGNORE
* INSERT ON DUPLICATE KEY UPDATE
* INSERT IGNORE ON DUPLICATE KEY UPDATE
* REPLACE
* LOAD DATA

这六种语句理论上都属于 INSERT 语句。

第一种，是最常见的 INSERT 语句，这里不多解释。

第二种，是当 INSERT 的时候遇到唯一约束冲突后（主键冲突、唯一索引冲突），忽略当前 INSERT 的行，并记一个 warning。当语句执行结束后，可以通过 `SHOW WARNINGS` 看到哪些行没有被插入。

第三种，是当冲突后，更新冲突行后插入数据。如果更新后的行跟表中另一行冲突，则返回错误。

第四种，是在上一种情况，更新后的行又跟另一行冲突后，不插入改行并显示为一个 warning。

第五种，是当冲突后，删除表上的冲突行，并继续尝试插入数据，如再次冲突，则继续删除标上冲突数据，直到表上没有与改行冲突的数据后，插入数据。

最后一种，规则与 INSERT IGNORE 相同，都是冲突即忽略，不同的是 LOAD DATA 的作用是将数据文件导入到表中，也就是其数据来源于 csv 数据文件。

本文主要介绍第一、二种（INSERT、INSERT IGNORE）的源码实现，第三、五种（INSERT ON DUPLICATE KEY UPDATE、REPLACE）将留到后续介绍。
INSERT IGNORE ON DUPLICATE KEY UPDATE 由于是在 INSERT ON DUPLICATE KEY UPDATE 上做了些特殊处理，LOAD DATA 由于是 INSERT IGNORE 的特殊实现，将不再详细介绍。

# INSERT 语句

几种 INSERT 语句的最大不同在于执行层面，这里接着[《Insert 语句概览》](https://zhuanlan.zhihu.com/p/34512827)来讲执行。不记得前面内容的同学可以返回去看原文章。

INSERT 的执行逻辑在 executor/insert.go 中。其实前面讲的前四种 INSERT 的执行逻辑都在这个文件里。这里先讲最普通的 INSERT。

InsertExec 是 INSERT 的执行器实现，其实现了 Executor 接口。在 Open 方法里进行一些初始化，Next 方法里执行，Close 方法里做一些清理工作。

在 Next 方法中，根据是否通过一个 SELECT 语句来获取数据（INSERT SELECT FROM），将 Next 流程分为，insertRows 和 insertRowsFromSelect。两个流程最终都会进入 exec 函数，执行 INSERT。

exec 函数里处理了前四种 INSERT 语句，其中本节要讲的普通 INSERT 直接进入了 insertOneRow。

在讲 insertOneRow 之前，我们先看一段 SQL。

```sql
CREATE TABLE t (i INT UNIQUE);
INSERT INTO t VALUES (1);
BEGIN;
INSERT INTO t VALUES (1);
COMMIT;
```

把这段 SQL 分别一行行地粘在 TiDB 和 MySQL 中看下结果。

MySQL: 

```
mysql> CREATE TABLE t (i INT UNIQUE);
Query OK, 0 rows affected (0.15 sec)

mysql> INSERT INTO t VALUES (1);
Query OK, 1 row affected (0.01 sec)

mysql> BEGIN;
Query OK, 0 rows affected (0.00 sec)

mysql> INSERT INTO t VALUES (1);
ERROR 1062 (23000): Duplicate entry '1' for key 'i'
mysql> COMMIT;
Query OK, 0 rows affected (0.11 sec)
```

TiDB:

```
mysql> CREATE TABLE t (i INT UNIQUE);
Query OK, 0 rows affected (1.04 sec)

mysql> INSERT INTO t VALUES (1);
Query OK, 1 row affected (0.12 sec)

mysql> BEGIN;
Query OK, 0 rows affected (0.01 sec)

mysql> INSERT INTO t VALUES (1);
Query OK, 1 row affected (0.00 sec)

mysql> COMMIT;
ERROR 1062 (23000): Duplicate entry '1' for key 'i'
```

可以看出来，对于 INSERT 语句 TiDB 是在事务提交的时候才做冲突检测的。而 MySQL 是在语句执行的时候做的检测。
这是因为在 insertOneRow 中设置了 PresumeKeyNotExists 选项，所有的 INSERT 都首先假设插入不会发生冲突，然后到提交的时候，统一将整个事务里的插入的行做批量检测。

# INSERT IGNORE 语句

INSERT IGNORE 的语义在前面已经介绍了。由于之前介绍了，普通 INSERT 在提交的时候才检查，那 INSERT IGNORE 是否可以呢？答案是不行的。因为，

1. INSERT IGNORE 如果在提交时检测，那事务模块就需要知道哪些行需要忽略，哪些直接报错回滚，这无疑增加了模块间的耦合。
1. 用户希望立刻获取 INSERT IGNORE 有哪些行没有写入进去。即，立刻通过 `SHOW WARNINGS` 看到哪些行实际不会写。

这就需要在执行 INSERT IGNORE 的时候，及时检查数据的冲突情况。一个显而易见的做法是，把需要插入的数据试着读出来，当发现冲突后，记一个 warning，再继续下一行。但是对于一个语句插入多行的情况，就需要反复从 TiKV 读取数据来进行检测。于是，TiDB 实现了 batchChecker，代码在 executor/batch_checker.go。

在 batchChecker 中，

首先，将拿待插入的数据，将其中可能冲突的唯一约束在 getKeysNeedCheck 中构造成 key（TiDB 是通过构造唯一的 key 来实现唯一约束的，详见[《三篇文章了解 TiDB 技术内幕——说计算》](https://zhuanlan.zhihu.com/p/27108657)），将构造出来的 key 通过 BatchGetValues 一次性读上来，读到的都是冲突的数据。

然后，拿即将插入的数据的 key 到 BatchGetValues 的结果中进行查询，查到的冲突的行，构造好 warning 信息，然后开始下一行，查不到的行，就可以进行安全的 INSERT 了。这部分的实现在 batchCheckAndInsert 中。