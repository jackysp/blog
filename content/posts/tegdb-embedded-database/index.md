---
title: "TegDB: Notes from Building a Small Embedded Database"
slug: "tegdb-embedded-database"
date: "2026-05-24T20:35:00+08:00"
draft: false
summary: "TegDB is a small embedded database experiment focused on simplicity, reliability, WAL recovery, and a SQL-like interface."
description: "A project note on TegDB, a lightweight embedded database engine with ACID transactions, WAL recovery, B+tree indexing, and a SQL-like interface."
categories: ["Databases"]
tags: ["tegdb", "database", "rust", "embedded-database", "storage-engine"]
---

TegDB is a lightweight embedded database engine with a SQL-like interface. It is written in Rust and focuses on simplicity, reliability, and predictable behavior.

The project is not trying to compete with SQLite. It is a learning and systems-design project: what happens when you build the parts of a small database yourself?

## Design philosophy

The most important choice is simplicity. TegDB uses a deliberately constrained architecture:

- embedded engine
- single-process access
- write-ahead logging
- crash recovery
- B+tree-style indexing
- schema and constraint checks
- SQL-like query surface

Avoiding broad concurrency is not a weakness for this kind of project. It reduces the number of failure modes and makes the storage path easier to reason about.

## Why build a database

Database internals are easier to understand when you have to implement the boring parts:

- how records are serialized
- how pages are found
- how an index points to storage
- when a transaction becomes durable
- how recovery decides what to replay
- how a query stops early with `LIMIT`

Reading database code is useful. Writing a small one makes the tradeoffs harder to ignore.

## Reliability work

The most interesting code in a database is often not the happy path. TegDB spends attention on:

- write-ahead log commit markers
- rollback behavior
- partial write handling
- file locking
- recovery after crash
- corruption boundaries

These are the parts that turn “data structure on disk” into “database.”

## What I learned

The database abstraction is expensive because it hides many coordinated guarantees. Even a small embedded engine has to care about durability, serialization, schema behavior, query planning shortcuts, and operational failure.

The lesson is not that every app should have a custom database. The lesson is the opposite: after building even a small one, you gain more respect for mature storage engines.

## Open source status

TegDB is public because the project is mainly educational and architectural. It is useful as a record of experiments in storage design, not as a claim that it should replace established embedded databases.
