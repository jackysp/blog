---
title: "How to Test CockroachDB Performance Using Benchmarksql"
slug: "how-to-test-cockroachdb-performance-using-benchmarksql"
tags: ['cockroachdb', 'database', 'benchmark', 'tpcc']
date: 2018-07-06T21:21:00+08:00
---

## Why Test TPC-C

First of all, TPC-C is the de facto OLTP benchmark standard. It is a set of specifications, and any database can publish its test results under this standard, so there's no issue of quarreling over the testing tools used.

Secondly, TPC-C is closer to real-world scenarios as it includes a transaction model within it. In the flow of this transaction model, there are both high-frequency simple transaction statements and low-frequency inventory query statements. Therefore, it tests the database more comprehensively and practically.

## Testing TPC-C on CockroachDB

This year, CockroachDB released its TPC-C performance results. However, unfortunately, they did not use a tool recognized by the database industry that implements the TPC-C standard for testing. Instead, they used their own implementation of a TPC-C tool. The compliance level of this tool was not recognized. In the white paper officially released by them, it is also mentioned that this TPC-C cannot be compared with the TPC-C standard.

Therefore, I thought of using a highly recognized tool in the industry for testing. Here, I chose Benchmarksql version 5.0.

Benchmarksql 5.0 supports the PostgreSQL protocol, Oracle protocol, and MySQL protocol (the MySQL protocol is supported in the code, but the author hasn't fully tested it, so the official documentation doesn't mention MySQL). Among these, the PostgreSQL protocol is supported by CockroachDB.

### Test Preparation

After preparing the Benchmarksql code, don't rush into testing. There are three main pitfalls here that need to be addressed first.

1. **CockroachDB does not support adding a primary key after table creation.** Therefore, you need to include the primary key when creating the table. Specifically, in the `run` folder under the root directory of the Benchmarksql code, create a `sql.cdb` folder. Copy `tableCreates.sql` and `indexCreates.sql` from the `sql.common` folder at the same level into `sql.cdb`. Then move the primary keys in `indexCreates.sql` into the table creation statements in `tableCreates.sql`. For how to define indexes while creating tables, please refer to the database documentation syntax via Google.

2. **CockroachDB is a "strongly typed" database.** This is my own way of describing it. It has a rather peculiar behavior: when you add different data types (e.g., int + float), it will report an error saying, "InternalError: unsupported binary operator: \<int> + \<float>". Generally, databases don't behave like this; most would perform some implicit conversions, or in other words, they are very tolerant of SQL writers. But CockroachDB is unique in that if you don't specify the type, it reports an error. This greatly reduces the burden of type inference in its internal implementation.

   This behavior causes Benchmarksql to fail to run the tests properly. The solution is to add the required type at the position where the error occurs. For example, change `update t set i = i + ?;` (the `?` is generally filled in using `prepare/execute`) to `update t set i = i + ?::DECIMAL;`. Yes, CockroachDB specifies types explicitly by adding `::<type_name>` at the end. But strangely, not all additions require type specification.

3. **CockroachDB does not support `SELECT FOR UPDATE`.** This is the easiest to solve: comment out all `FOR UPDATE` clauses in Benchmarksql. CockroachDB itself supports the serializable isolation level; lacking `FOR UPDATE` doesn't affect consistency.

### Starting the Test

After overcoming the pitfalls mentioned above, you can proceed with the normal testing process: creating the database, creating tables and indexes, importing data, and testing. You can refer to Benchmarksql's `HOW-TO-RUN.txt`.

### Test Results

On my test machine with 40 cores, 128 GB of memory, and SSD, under 100 warehouses, the tpmC is approximately 5,000. This is about one-tenth of PostgreSQL 10 on the same machine. PostgreSQL can reach around 500,000 tpmC.
