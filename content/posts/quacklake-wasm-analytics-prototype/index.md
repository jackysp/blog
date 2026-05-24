---
title: "QuackLake: A DuckDB-WASM Analytics Prototype"
slug: "quacklake-wasm-analytics-prototype"
date: "2026-05-24T20:45:00+08:00"
draft: false
summary: "QuackLake explores a WASM-first analytics shape with DuckDB-WASM, object storage, a range gateway, and a small control plane."
description: "A project note on QuackLake, a prototype combining DuckDB-WASM compute, MinIO object storage, a Rust API, and an HTTP range gateway."
categories: ["Databases"]
tags: ["duckdb", "wasm", "analytics", "object-storage", "rust"]
---

QuackLake is a WASM-first analytics prototype. It combines DuckDB-WASM compute, MinIO object storage, a Rust control plane, and an HTTP range gateway.

The project is deliberately prototype-shaped. It asks what an analytics stack looks like when browser or WASM compute is treated as a real part of the system rather than only a demo surface.

## Components

The local stack is split into small services:

- API control plane
- HTTP range gateway over object storage
- Node runner using DuckDB-WASM
- browser query UI
- MinIO for S3-compatible storage

That separation makes the data flow easier to inspect:

1. data lives in object storage
2. range requests expose only needed bytes
3. DuckDB-WASM runs queries
4. lineage or job metadata can be tracked by the control plane

## Why DuckDB-WASM

DuckDB is already a strong fit for local analytics. DuckDB-WASM adds a different deployment shape: query execution can move closer to the browser, a worker, or a constrained runtime.

The attraction is not that every analytics job should run in the browser. The attraction is that the compute boundary becomes flexible.

## What the prototype tests

QuackLake is useful for testing system questions:

- how painful are range requests in practice?
- where should metadata live?
- what should the API own?
- when does browser compute become awkward?
- how much can object storage simplify the backend?

These are architectural questions, not UI questions.

## What I learned

WASM analytics is promising, but the hard parts move around. Query execution can be surprisingly capable, while data access, file layout, caching, and observability become the real design surface.

The range gateway is a good example. It sounds like plumbing, but it shapes whether the system feels smooth or fragile.

## Current status

QuackLake is private and experimental. I would not present it as a finished product. Its value is as a small lab for object-storage-first analytics and DuckDB-WASM deployment patterns.
