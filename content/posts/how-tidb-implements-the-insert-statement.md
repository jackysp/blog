---
title: "How TiDB Implements the INSERT Statement"  
slug: "how-tidb-implements-the-insert-statement"
tags: ['database', 'optimization']
date: 2018-07-11T14:18:00+08:00  
draft: false
---
In a previous article [“TiDB Source Code Reading Series (4) Overview of INSERT Statement”](https://cn.pingcap.com/blog/tidb-source-code-reading-4), we introduced the general process of the INSERT statement. Why write a separate article for INSERT? Because in TiDB, simply inserting a piece of data is the simplest and most common case. It becomes more complex when defining various behaviors within the INSERT statement, such as how to handle situations with Unique Key conflicts: Should we return an error? Ignore the current data insertion? Or overwrite existing data? Therefore, this article will continue to delve into the INSERT statement.

This article will first introduce the classification of INSERT statements in TiDB, along with the syntax and semantics of each statement, and then describe the source code implementation of the five types of INSERT statements.

## Types of INSERT Statements

In broad terms, TiDB has the following six types of INSERT statements:

* `Basic INSERT`
* `INSERT IGNORE`
* `INSERT ON DUPLICATE KEY UPDATE`
* `INSERT IGNORE ON DUPLICATE KEY UPDATE`
* `REPLACE`
* `LOAD DATA`

In theory, all six statements belong to the category of INSERT statements.

The first one, `Basic INSERT`, is the most common INSERT statement, using the syntax `INSERT INTO VALUES ()`. It implies inserting a record, and if a unique constraint conflict occurs (such as primary key conflict, unique index conflict), it returns an execution failure.

The second, with the syntax `INSERT IGNORE INTO VALUES ()`, ignores the current INSERT row if a unique constraint conflict occurs and logs a warning. After the statement execution finishes, you can use `SHOW WARNINGS` to see which rows were not inserted.

The third one, with the syntax `INSERT INTO VALUES () ON DUPLICATE KEY UPDATE`, updates the conflicting row, then inserts data if there is a conflict. If the updated row conflicts with another row in the table, it returns an error.

The fourth one, similar to the previous case, if the updated row conflicts with another row, this does not insert the row and shows a warning.

The fifth one, with the syntax `REPLACE INTO VALUES ()`, deletes the conflicting row in the table after a conflict and continues to attempt data insertion. If another conflict occurs again, it continues to delete conflicting data on the table until there is no conflicting data left in the table, then inserts the data.

The last one, using the syntax `LOAD DATA INFILE INTO`, has semantics similar to `INSERT IGNORE`, both ignoring conflicts. The difference is that `LOAD DATA` imports data files into a table, meaning its data source is a CSV data file.

Since `INSERT IGNORE ON DUPLICATE KEY UPDATE` involves special processing on `INSERT ON DUPLICATE KEY UPDATE`, it won't be explained in detail separately but will be covered in the same section. Due to the unique nature of `LOAD DATA`, it will be discussed in other chapters.

## Basic INSERT Statement

The major differences among the several INSERT statements lie in the execution level. Continuing from the [“TiDB Source Code Reading Series (4) Overview of INSERT Statement”](https://cn.pingcap.com/blog/tidb-source-code-reading-4), here is the statement execution process. Those who do not remember the previous content can refer back to the original article.

INSERT's execution logic is located in [executor/insert.go](https://github.com/pingcap/tidb/blob/ab332eba2a04bc0a996aa72e36190c779768d0f1/executor/insert.go). In fact, the execution logic for all four types of INSERT statements covered previously is in this file. Here, we first discuss the most basic `Basic INSERT`.

`InsertExec` is an implementation of the INSERT executor, conforming to the Executor interface. The most important methods are the following three interfaces:

* Open: Performs some initialization
* Next: Executes the write operation
* Close: Performs some cleanup tasks

Among them, the most important and complex is the Next method. Depending on whether a SELECT statement is used to retrieve data (`INSERT SELECT FROM`), the Next process is divided into two branches: [insertRows](https://github.com/pingcap/tidb/blob/ab332eba2a04bc0a996aa72e36190c779768d0f1/executor/insert_common.go#L180:24) and [insertRowsFromSelect](https://github.com/pingcap/tidb/blob/ab332eba2a04bc0a996aa72e36190c779768d0f1/executor/insert_common.go#L277:24). Both processes eventually lead to the `exec` function to execute the INSERT.

In the `exec` function, the first four types of INSERT statements are processed together. The standard INSERT covered in this section directly enters [insertOneRow](https://github.com/pingcap/tidb/blob/5bdf34b9bba3fc4d3e50a773fa8e14d5fca166d5/executor/insert.go#L42:22).

Before discussing [insertOneRow](https://github.com/pingcap/tidb/blob/5bdf34b9bba3fc4d3e50a773fa8e14d5fca166d5/executor/insert.go#L42:22), let's look at a segment of SQL.

```sql
CREATE TABLE t (i INT UNIQUE);
INSERT INTO t VALUES (1);
BEGIN;
INSERT INTO t VALUES (1);
COMMIT;
```

Paste these lines of SQL sequentially into MySQL and TiDB to see the results.

MySQL:

```sql
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

```sql
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

As you can see, for INSERT statements, TiDB performs conflict detection at the time of transaction commit, whereas MySQL does it when the statement is executed. The reason for this is that TiDB is designed with a layered structure with TiKV; to ensure efficient execution, only read operations within a transaction must retrieve data from the storage engine, while all write operations are initially placed within the transaction's own [memDbBuffer](https://github.com/pingcap/tidb/blob/ab332eba2a04bc0a996aa72e36190c779768d0f1/kv/memdb_buffer.go#L31) in a single TiDB instance. The data is then written to TiKV as a batch during transaction commit. In the implementation, the [PresumeKeyNotExists](https://github.com/pingcap/tidb/blob/e28a81813cfd290296df32056d437ccd17f321fe/kv/kv.go#L23) option is set within [insertOneRow](https://github.com/pingcap/tidb/blob/5bdf34b9bba3fc4d3e50a773fa8e14d5fca166d5/executor/insert.go#L42:22), assuming that insertions will not encounter conflicts if no conflicts are detected locally, without needing to check for conflicting data in TiKV. These data are marked as pending verification, and the `BatchGet` interface is used during the commit process to batch check the whole transaction's pending data.

After all the data goes through [insertOneRow](https://github.com/pingcap/tidb/blob/5bdf34b9bba3fc4d3e50a773fa8e14d5fca166d5/executor/insert.go#L42:22) and completes the insertion, the INSERT statement essentially concludes. The remaining tasks involve setting the lastInsertID and other return information, and then returning the results to the client.

## INSERT IGNORE Statement

The semantics of `INSERT IGNORE` were introduced earlier. It was mentioned how a standard INSERT checks at the time of commit, but can `INSERT IGNORE` do the same? The answer is no, because:

1. If `INSERT IGNORE` is checked at the commit, the transaction module will need to know which rows should be ignored and which should immediately raise errors and roll back, undoubtedly increasing module coupling.
2. Users want to immediately know which rows were not inserted through `INSERT IGNORE`. In other words, they would like to see which rows were not actually inserted immediately through `SHOW WARNINGS`.

This requires checking data conflicts promptly when executing `INSERT IGNORE`. One obvious approach is to try reading the data intended for insertion, logging a warning when finding a conflict, and proceeding to the next row. However, if the statement inserts multiple rows, it would require repetitive reads from TiKV for conflict detection, which would be inefficient. Therefore, TiDB implements a [batchChecker](https://github.com/pingcap/tidb/blob/3c0bfc19b252c129f918ab645c5e7d34d0c3d154/executor/batch_checker.go#L43:6), with the code located in [executor/batch_checker.go](https://github.com/pingcap/tidb/blob/ab332eba2a04bc0a996aa72e36190c779768d0f1/executor/batch_checker.go).

In the [batchChecker](https://github.com/pingcap/tidb/blob/3c0bfc19b252c129f918ab645c5e7d34d0c3d154/executor/batch_checker.go#L43:6), first, prepare the data for insertion, constructing possible conflicting unique constraints into a key within [getKeysNeedCheck](https://github.com/pingcap/tidb/blob/3c0bfc19b252c129f918ab645c5e7d34d0c3d154/executor/batch_checker.go#L85:24). TiDB implements unique constraints by constructing unique keys, as detailed in [“Three Articles to Understand TiDB's Technical Inside Story – On Computation”](https://cn.pingcap.com/blog/tidb-internal-2/).

Then, pass the constructed keys through [BatchGetValues](https://github.com/pingcap/tidb/blob/c84a71d666b8732593e7a1f0ec3d9b730e50d7bf/kv/txn.go#L97:6) to read them all at once, resulting in a key-value map where those read are the conflicting data.

Finally, check the keys of the data intended for insertion against the results from [BatchGetValues](https://github.com/pingcap/tidb/blob/c84a71d666b8732593e7a1f0ec3d9b730e50d7bf/kv/txn.go#L97:6). If a conflicting row is found, prepare a warning message and proceed to the next row. If a conflicting row isn’t found, a safe INSERT can proceed. The implementation of this portion is found in [batchCheckAndInsert](https://github.com/pingcap/tidb/blob/ab332eba2a04bc0a996aa72e36190c779768d0f1/executor/insert_common.go#L490:24).

Similarly, after executing the insertion for all data, return information is set, and the execution results are returned to the client.

## INSERT ON DUPLICATE KEY UPDATE Statement

`INSERT ON DUPLICATE KEY UPDATE` is the most complex among the INSERT statements. Its semantic essence includes both an INSERT and an UPDATE. The complexity arises since during an UPDATE, a row can be updated to any valid version.

In the previous section, it was discussed how TiDB uses batching to implement conflict checking for special INSERT statements. The same method is used for `INSERT ON DUPLICATE KEY UPDATE`, but the implementation process is somewhat more complex due to the semantic complexity.

Initially, similar to `INSERT IGNORE`, the keys constructed from the data to be inserted are read out at once using [BatchGetValues](https://github.com/pingcap/tidb/blob/c84a71d666b8732593e7a1f0ec3d9b730e50d7bf/kv/txn.go#L97:6), resulting in a key-value map. Then, all records corresponding to the read keys are again read using a batch [BatchGetValues](https://github.com/pingcap/tidb/blob/c84a71d666b8732593e7a1f0ec3d9b730e50d7bf/kv/txn.go#L97:6), prepared for possible future UPDATE operations. The specific implementation is in [initDupOldRowValue](https://github.com/pingcap/tidb/blob/3c0bfc19b252c129f918ab645c5e7d34d0c3d154/executor/batch_checker.go#L225:24).

Then, during conflict checking, if a conflict occurs, an UPDATE is performed first. As discussed in the Basic INSERT section earlier, TiDB executes INSERT in TiKV during commit. Similarly, UPDATE is also executed in TiKV during commit. In this UPDATE process, unique constraint conflicts might still occur. If so, then an error is returned. If the statement is `INSERT IGNORE ON DUPLICATE KEY UPDATE`, this error is ignored, and the next row proceeds.

In the UPDATE from the previous step, another scenario can occur, as in the SQL below:

```sql
CREATE TABLE t (i INT UNIQUE);
INSERT INTO t VALUES (1), (1) ON DUPLICATE KEY UPDATE i = i;
```

Here, it is clear that there are no original data in the table; the INSERT in the second line cannot read out possibly conflicting data, but there is a conflict between the two rows of data intended to be inserted themselves. Correct execution here should involve the first 1 being inserted normally, with the second 1 encountering conflict and updating the first 1. Thus, it is necessary to handle it as follows: remove the key-value of the data updated in the previous step from the initial step's key-value map, reconstruct unique constraint keys and values for the data from the UPDATE based on table information, and add this key-value pair back into the initial key-value map for subsequent data conflict checking. The detail implementation is in [fillBackKeys](https://github.com/pingcap/tidb/blob/2fba9931c7ffbb6dd939d5b890508eaa21281b4f/executor/batch_checker.go#L232). This scenario also arises in other INSERT statements like `INSERT IGNORE`, `REPLACE`, and `LOAD DATA`. It is introduced here because `INSERT ON DUPLICATE KEY UPDATE` showcases the full functionality of the `batchChecker`.

Finally, after all data completes insertion/update, return information is set, and results are returned to the client.

## REPLACE Statement

Although the REPLACE statement appears as a separate type of DML, in examining its syntax, it is merely replacing INSERT with REPLACE compared to a standard `Basic INSERT`. The difference is that REPLACE is a one-to-many statement. Briefly, for a typical INSERT statement which needs to INSERT a row and encounters a unique constraint conflict, various treatments are available:

* Abandon the insert and return an error: `Basic INSERT`
* Abandon the insert without error: `INSERT IGNORE`
* Abandon the insert, turning it into updating the conflicting row. If the updated value conflicts again,
* Return an error: `INSERT ON DUPLICATE KEY UPDATE`
* No error: `INSERT IGNORE ON DUPLICATE KEY UPDATE`They all handle conflicts when a row of data conflicts with a row in the table differently. However, the REPLACE statement is distinct; it will delete all conflicting rows it encounters until there are no more conflicts, and then insert the data. If there are 5 unique indexes in the table, there could be 5 rows conflicting with the row waiting to be inserted. The REPLACE statement will delete these 5 rows all at once and then insert its own data. See the SQL below:

```sql
CREATE TABLE t (
i int unique,
j int unique,
k int unique,
l int unique,
m int unique);
INSERT INTO t VALUES
(1, 1, 1, 1, 1),
(2, 2, 2, 2, 2),
(3, 3, 3, 3, 3),
(4, 4, 4, 4, 4);
REPLACE INTO t VALUES (1, 2, 3, 4, 5);
SELECT * FROM t;
i j k l m
1 2 3 4 5
```

After execution, it actually affects 5 rows of data.

Once we understand the uniqueness of the REPLACE statement, we can more easily comprehend its specific implementation.

Similar to the INSERT statement, the main execution part of the REPLACE statement is also in its Next method. Unlike INSERT, it passes its own [exec](https://github.com/pingcap/tidb/blob/f6dbad0f5c3cc42cafdfa00275abbd2197b8376b/executor/replace.go#L160) method through [insertRowsFromSelect](https://github.com/pingcap/tidb/blob/ab332eba2a04bc0a996aa72e36190c779768d0f1/executor/insert_common.go#L277:24) and [insertRows](https://github.com/pingcap/tidb/blob/ab332eba2a04bc0a996aa72e36190c779768d0f1/executor/insert_common.go#L180:24). In [exec](https://github.com/pingcap/tidb/blob/f6dbad0f5c3cc42cafdfa00275abbd2197b8376b/executor/replace.go#L160), it calls [replaceRow](https://github.com/pingcap/tidb/blob/f6dbad0f5c3cc42cafdfa00275abbd2197b8376b/executor/replace.go#L95), which also uses batch conflict detection in [batchChecker](https://github.com/pingcap/tidb/blob/3c0bfc19b252c129f918ab645c5e7d34d0c3d154/executor/batch_checker.go#L43:6). The difference from INSERT is that all detected conflicts are deleted here, and finally, the row to be inserted is written in.

## In Conclusion

The INSERT statement is among the most complex, versatile, and powerful of all DML statements. It includes statements like `INSERT ON DUPLICATE UPDATE`, which can perform both INSERT and UPDATE operations, and REPLACE, where a single row of data can impact many rows. The INSERT statement itself can be connected to a SELECT statement as input for the data to be inserted, thus its implementation is influenced by the planner (for more on the planner, see related source code reading articles: [Part 7: Rule-Based Optimization](https://cn.pingcap.com/blog/tidb-source-code-reading-7/) and [Part 8: Cost-Based Optimization](https://cn.pingcap.com/blog/tidb-source-code-reading-8/)). Familiarity with the implementation of various INSERT-related statements in TiDB can help readers use these statements more reasonably and efficiently in the future. Additionally, readers interested in contributing code to TiDB can also gain a quicker understanding of this part of the implementation through this article.
