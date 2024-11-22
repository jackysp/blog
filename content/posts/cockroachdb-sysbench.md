---
title: "How to Test CockroachDB Performance Using Sysbench"
date: 2018-06-11T13:50:00+08:00
---

# Compiling Sysbench with pgsql Support

CockroachDB uses the PostgreSQL protocol. If you want to use Sysbench for testing, you need to enable pg protocol support in Sysbench. Sysbench already supports the pg protocol, but it is not enabled by default during compilation. You can configure it with the following command:

```shell
./configure --with-pgsql
```

Of course, preliminary work involves downloading the Sysbench source code and installing the necessary PostgreSQL header files required for compilation (you can use `yum` or `sudo` to install them).

# Testing

The testing method is no different from testing MySQL or PostgreSQL; you can test any of the create, read, update, delete (CRUD) operations you like. The only thing to note is to set `auto_inc` to `off`. 

This is because CockroachDB's auto-increment behavior is different from PostgreSQL's. It generates a unique `id`, but it does not guarantee that the `id`s are sequential or incremental. This is fine when inserting data. However, during delete, update, or query operations, since all SQL statements use `id` as the condition for these operations, you may encounter situations where data cannot be found.

That is:

When `auto_inc = on` (which is the default value in Sysbench)

**Table Structure**

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

**Data**

```sql
root@:26257/sbtest> SELECT id FROM sbtest1 ORDER BY id LIMIT 1;
+--------------------+
|         id         |
+--------------------+
| 354033003848892419 |
+--------------------+
```

As you can see, the data does not start from `1`, nor is it sequential. Normally, the `id` in a Sysbench table should be within the range `[1, table_size]`.

**SQL**

```sql
UPDATE sbtest%u SET k = k + 1 WHERE id = ?
```

Taking the `UPDATE` statement as an example, `id` is used as the query condition. Sysbench assumes that this `id` should be between `[1, table_size]`, but in reality, it's not.

**Example of Correct Testing Command Line**

```shell
sysbench --db-driver=pgsql --pgsql-host=127.0.0.1 --pgsql-port=26257 --pgsql-user=root --pgsql-db=sbtest \
        --time=180 --threads=50 --report-interval=10 --tables=32 --table-size=10000000 \
        oltp_update_index \
        --sum_ranges=50 --distinct_ranges=50 --range_size=100 --simple_ranges=100 --order_ranges=100 \
        --index_updates=100 --non_index_updates=10 --auto_inc=off prepare/run/cleanup
```

### INSERT Testing

Let's discuss the INSERT test separately. The INSERT test refers to Sysbench's `oltp_insert`. The characteristic of this test is that when `auto_inc` is `on`, data is inserted during the prepare phase of the test; otherwise, only the table is created without inserting data. Because when `auto_inc` is `on`, after the prepare phase, during the run phase, the inserted data will not cause conflicts due to the guarantee of the auto-increment column. When `auto_inc` is `off`, the `id` of the data inserted during the run phase is randomly assigned, which aligns with some actual testing scenarios.

For CockroachDB, when testing INSERT operations with `auto_inc` set to `off`, after the prepare phase, during the run phase of data insertion, you can observe the monitoring metrics (by connecting to CockroachDB's HTTP port) under the "Distribution" section in "KV Transactions". You'll notice a large number of "Fast-path Committed" transactions. This indicates that transactions are committed using one-phase commit (1PC). That is, the data involved in the transaction does not span across CockroachDB nodes, so there's no need to ensure consistency through two-phase commit transactions. This is an optimization in CockroachDB, which is very effective in INSERT tests and can deliver excellent performance.

If `auto_inc` is `on`, although for other tests that require read-before-write operations, the results in CockroachDB might be inflated, it is still fair for the INSERT test. If time permits, you can supplement the tests to see the differences.