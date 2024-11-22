---
title: "How TiDB Implements the INSERT Statement"  
date: 2018-07-11T14:18:00+08:00  
draft: true  
---

In the previous article ["Overview of the Insert Statement"](https://zhuanlan.zhihu.com/p/34512827), the general process of the INSERT statement was introduced. This article will explain in detail the implementation of several types of INSERT statements in TiDB.

# Types of INSERT Statements

In TiDB, there are the following types of INSERT statements:

* INSERT
* INSERT IGNORE
* INSERT ON DUPLICATE KEY UPDATE
* INSERT IGNORE ON DUPLICATE KEY UPDATE
* REPLACE
* LOAD DATA

These six statements theoretically fall under the category of INSERT statements.

The first type is the most common INSERT statement, which needs no further explanation.

The second type, INSERT IGNORE, skips the current row when encountering a unique constraint conflict (primary key conflict, unique index conflict) and logs a warning. After the execution of the statement, you can see which rows were not inserted through `SHOW WARNINGS`.

The third type, INSERT ON DUPLICATE KEY UPDATE, updates the conflicting row and then inserts the data. If the updated row conflicts with another row in the table, an error is returned.

The fourth type, INSERT IGNORE ON DUPLICATE KEY UPDATE, does not insert the row and displays a warning when the updated row conflicts with another row after the initial conflict.

The fifth type, REPLACE, deletes the conflicting row from the table and continues trying to insert data. If another conflict occurs, it continues deleting the conflicting data until there is no more conflicting data in the table, then inserts the data.

The last type, LOAD DATA, follows the same rule as INSERT IGNORE—it ignores conflicts. However, LOAD DATA's purpose is to import data from a file into a table, meaning the data comes from a CSV data file.

This article mainly focuses on the source code implementation of the first and second types (INSERT, INSERT IGNORE), while the third and fifth types (INSERT ON DUPLICATE KEY UPDATE, REPLACE) will be introduced later. INSERT IGNORE ON DUPLICATE KEY UPDATE involves some special handling on top of INSERT ON DUPLICATE KEY UPDATE, and LOAD DATA is a special implementation of INSERT IGNORE, so they will not be detailed here.

# INSERT Statement

The major difference between these various INSERT statements lies in the execution layer. We will continue with the explanation from ["Overview of the Insert Statement"](https://zhuanlan.zhihu.com/p/34512827). If you don’t remember the previous content, feel free to refer back to the original article.

The execution logic of INSERT is located in executor/insert.go. In fact, the execution logic of the first four INSERT types is all in this file. Let’s first discuss the most basic INSERT.

InsertExec is the executor implementation for INSERT, which implements the Executor interface. It performs some initialization in the Open method, executes in the Next method, and does some cleanup in the Close method.

In the Next method, based on whether the data is acquired through a SELECT statement (INSERT INTO ... SELECT FROM), the Next process is divided into insertRows and insertRowsFromSelect. Both processes eventually enter the exec function to execute the INSERT.

Within the exec function, the first four types of INSERT statements are handled, with the regular INSERT directly entering the insertOneRow.

Before discussing insertOneRow, let's look at a piece of SQL.

```sql
CREATE TABLE t (i INT UNIQUE);
INSERT INTO t VALUES (1);
BEGIN;
INSERT INTO t VALUES (1);
COMMIT;
```

Execute this SQL line by line in both TiDB and MySQL to see the results.

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

As can be seen, for the INSERT statement, TiDB performs conflict detection at the time of transaction commitment, while MySQL performs the detection when the statement is executed. This is because in insertOneRow, the PresumeKeyNotExists option is set, meaning all INSERTs initially assume that no conflicts will occur, and conflict detection is deferred to the commitment phase to perform a bulk check on all rows inserted in the transaction.

# INSERT IGNORE Statement

The semantics of INSERT IGNORE have been introduced earlier. Since usual INSERTs are checked for conflicts at commitment, can INSERT IGNORE follow this approach as well? The answer is no, due to the following reasons:

1. If INSERT IGNORE checks for conflicts at commitment, the transaction module would need to know which rows to ignore and which rows to error and rollback, greatly increasing module coupling.
2. Users expect to immediately see which rows were not inserted under INSERT IGNORE. That is, they want to immediately use `SHOW WARNINGS` to know which rows were not actually written.

This requires immediate conflict detection when executing INSERT IGNORE. An obvious approach would be to try reading out the data before insertion, log a warning upon discovering a conflict, and then proceed to the next row. However, for situations where multiple rows are inserted in one statement, it would repeatedly read data from TiKV for detection. Therefore, TiDB implements batchChecker, with code located in executor/batch_checker.go.

In batchChecker:

First, the unique constraints that could potentially conflict with the data to be inserted are constructed into keys via getKeysNeedCheck (TiDB uses unique keys to enforce uniqueness constraints, detailed in ["Three Articles to Understand the Technical Inside Story of TiDB - Computation"](https://zhuanlan.zhihu.com/p/27108657)), and the constructed keys are read together via BatchGetValues, fetching only the conflicting data.

Then, the keys of the data to be inserted are checked against the results from BatchGetValues. Rows found to be in conflict will have a warning constructed, before moving on to the next row. Rows without conflict can be safely INSERTed. This process is implemented in batchCheckAndInsert.