---
title: "如何用 Sysbench 测试 CockroachDB 性能"
date: 2018-06-11T13:50:00+08:00
---

# 为 Sysbench 编译 pgsql 的支持

CockroachDB 使用的是 PostgreSQL 协议，如果想使用 Sysbench 进行测试，则需要 Sysbench 支持 pg 协议。Sysbench 本身已经支持了 pg 协议，只是在编译的时候默认不开启。
通过以下命令即可配置开启：

```shell
./configure --with-pgsql
```

当然，前期工作需要下载 Sysbench 的源代码，以及安装 pg 的一些编译所需要的头文件（yum 或者 sudo 就可以了）。

# 测试

测试方式跟测试 MySQL/Postgres 没有差别，增删改查想测哪个都可以。唯一需要注意的是，将 auto_inc 置为 off。
因为 CockroachDB 的 auto increment 行为跟 pg 是不一样的，它会生成一个唯一的 id，但是不保证连续、自增。这样在插入数据的时候是没问题的。
但是，在删、改、查中，由于所有 SQL 都是通过 id 为条件进行的删、改、查，因此，会出现找不到数据的情况。

即：

## auto_inc = on (on 为 Sysbench 默认值)

### 表结构

```sql
CREATE TABLE sbtest1 (
       id INT NOT NULL DEFAULT unique_rowid(),
       k INTEGER NOT NULL DEFAULT 0:::INT,
       c STRING(120) NOT NULL DEFAULT '':::STRING,
       pad STRING(60) NOT NULL DEFAULT '':::STRING,
       CONSTRAINT ""primary"" PRIMARY KEY (id ASC),
       INDEX k_1 (k ASC),
       FAMILY ""primary"" (id, k, c, pad)
)
```

### 数据

```sql
root@:26257/sbtest> select id from sbtest1 order by id limit 1;
+--------------------+
|         id         |
+--------------------+
| 354033003848892419 |
+--------------------+
```

可以看到数据不是从 1 开始的，其实也不是连续的。正常 Sysbench 表的 id 应该是 [1, table_size]，这个范围。

### SQL

```sql
UPDATE sbtest%u SET k=k+1 WHERE id=?
```

以 UPDATE 语句为例，id 是作为查询条件存在的，Sysbench 会认为这个 id 应该在 [1, table_size] 之间。实际则没有。

### 测试命令行举例

```shell
sysbench --db-driver=pgsql --pgsql-host=127.0.0.1 --pgsql-port=26257 --pgsql-user=root --pgsql-db=sbtest \
        --time=180 --threads=50 --report-interval=10 --tables=32 --table-size=10000000 \
        oltp_update_index \
        --sum_ranges=50 --distinct_ranges=50 --range_size=100  --simple_ranges=100 --order_ranges=100 --index_updates=100  --non_index_updates=10 --auto_inc=off prepare/run/cleanup
```