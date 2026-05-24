---
title: "tegdb-server: Putting a PostgreSQL-Compatible Protocol in Front of TegDB"
slug: "tegdb-server-postgres-compatible"
date: "2026-05-24T21:00:00+08:00"
draft: false
summary: "tegdb-server explores how a small embedded database can be exposed through a PostgreSQL-compatible server surface."
description: "A project note on tegdb-server, a Rust server that puts a PostgreSQL-compatible protocol and network boundary in front of the TegDB embedded database."
categories: ["Databases"]
tags: ["tegdb-server", "postgresql", "database-server", "rust", "protocol"]
---

`tegdb-server` is a PostgreSQL-compatible database server built on top of TegDB. It explores what changes when an embedded database becomes a networked service.

The project is small, but the architectural jump is large.

## Why add a server

An embedded database can keep many assumptions local:

- one process owns access
- file paths are local
- query state is in-process
- errors are library errors
- clients are application code

A server changes the boundary. Now there are connections, protocol messages, authentication questions, configuration, network errors, allocation pressure, and client compatibility expectations.

That is why this project exists: to study that boundary.

## PostgreSQL compatibility

PostgreSQL compatibility is useful because it gives the project a familiar client surface. If a normal client can connect, the database becomes easier to test and demonstrate.

But compatibility is also a trap. The PostgreSQL ecosystem expects a lot:

- protocol behavior
- type handling
- error responses
- transaction semantics
- SQL behavior
- metadata queries

The right goal for a small project is progressive compatibility, not pretending to be PostgreSQL.

## Storage boundary

`tegdb-server` keeps TegDB as the storage engine and adds a server layer in front. That separation is useful:

- TegDB owns on-disk behavior
- the server owns connections and protocol handling
- configuration stays explicit
- future distribution experiments have a place to attach

The project README frames this as progressive scalability from single-node to more distributed deployment shapes. That is ambitious, but it starts with a concrete first step: one server in front of one storage engine.

## What I learned

The protocol path has different performance concerns from the storage path. Per-query allocations, message parsing, response construction, and connection lifecycle can dominate before the storage engine becomes interesting.

This is a useful reminder: a database is not only its storage engine. It is also a wire protocol, client contract, operations surface, and set of compatibility promises.

## Open source status

`tegdb-server` is public because it pairs naturally with the public TegDB experiment. It is best read as a learning project about database server boundaries.
