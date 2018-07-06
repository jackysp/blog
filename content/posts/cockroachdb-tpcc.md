---
title: "如何用 Benchmarksql 测试 CockroachDB 性能"
date: 2018-07-06T21:21:00+08:00
---

# 为什么要测 TPC-C

首先，TPC-C 才是事实上的 OLTP Benchmark 标准。其本身是一套规范，任何数据库都可以公布其在该标准下的测试的结果，所以也就没有什么挑工具毛病的问题了。

其次，TPC-C 本身更贴近真实场景，其本身是有一个交易模型在里面。在这个交易模型的流程里，即存在高频的简单交易语句，也存在低频的库存查询语句。所以，其本身对数据库的考验更加全面且实用。

# CockroachDB 测试 TPC-C

CockroachDB 在今年公布了其 TPC-C 性能。不过，非常遗憾的是，它没有用公认的数据库业界实现了 TPC-C 标准的工具来测试。而是使用了自家实现的一套 TPC-C 工具来测试的。其规范程度没有得到认可。在其官方发布的白皮书中，也提到这套 TPC-C 不能与 TPC-C 标准进行比较。

所以，在这里，本人想到用业界认可度高的工具进行测试。这里选择了 Benchmarksql 最新版 5.0。

Benchmarksql 5.0 支持 PostgreSQL 协议、Oracle 协议以及 MySQL 协议（MySQL 协议在代码上是支持的，只是作者没有充分测试，因此，官方文档中没有提 MySQL）。其中，PostgreSQL 协议是 CockroachDB 支持的。

## 测试准备

在准备好 Benchmarksql 的代码后，先别急于测试。这里有三个主要的坑，需要先处理一下。

1. CockroachDB 不支持后加主键。因此，需要在建表语句中先将主键一同创建好。具体，可以在 Benchmarksql 代码跟目录下的 run 文件夹下，创建 sql.cdb 文件夹，在其中拷贝来自同一级的 sql.common 文件夹下的 tableCreates.sql 和 indexCreates.sql 到 sql.cdb 中。然后将 indexCreates 里的 primary key 移到 tableCreates.sql 里的建表语句中。具体怎么在建表的同时定义索引，这个就请 Google 数据库文档的语法吧。
1. CockroachDB 是一个"强类型"数据库。这个说法是我自己想的。它有个比较奇怪的行为，就是当你用一个不同类型相加时（比如 int + float），它会报错说，"InternalError: unsupported binary operator: <int> + <float>"。一般数据库都不会这样，大多数的做法是，做一些隐式的转换。或者说，对写 SQL 的人容忍度非常高。但是 CockroachDB 就别具一格，不指定类型就是报错。这样很大程度上减少了内部实现里类型推倒的负担。
	这个行为在 Benchmarksql 里的就成了没法正常跑完测试。解决方案就是，在报错的位置加上需要的类型，比如 update t set i = i + ?; （这个 ? 一般是通过 preppare/execute 来填值用的）改写成 update t set i = i + ?::DECIMAL; 。对，CockroachDB 就是通过在后面加 ::<类型名> 来显示指定类型的。但是非常奇怪的是，也不是所有的加都需要类型指定。
1. CockroachDB 不支持 select for update 。这个最好解决，把 Benchmarksql 里的 for udpate 全都注释掉吧。CockroachDB 本身支持可串行化隔离级别，没有 for update 不影响一致性。

## 开始测试

踩完上面的坑就可以正常测试了。创建数据库，建表和索引，导入数据，测试。参考 Benchmarksql 的 HOW-TO-RUN.txt 就可以了。

## 测试结果

在我的测试机上，40 核、128 内存、SSD，100 个 warehouse 下，tpmc 大概 5000。是同一机器上 PostgreSQL 10 的 1/10。PostgreSQL 大概能跑到 50 万 tpmc。