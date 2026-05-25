---
title: "scale-kv: A Storage Experiment About Complexity"
slug: "scale-kv-storage-experiment"
date: "2026-05-24T08:50:00+08:00"
draft: false
summary: "scale-kv is a Rust storage experiment that explores transactional KV, page structures, quorum behavior, and distributed-system complexity."
description: "A project note on scale-kv, a Rust experiment with transactional KV storage, page B+trees, quorum commit paths, Cap'n Proto RPC, and storage-system design notes."
categories: ["Databases"]
tags: ["scale-kv", "storage", "rust", "distributed-systems", "kv-store"]
---

`scale-kv` is a Rust storage experiment. It contains transactional KV code, page structures, quorum client paths, Cap'n Proto RPC, performance notes, and a growing set of documents about capacity, observability, fault drills, and roadmap choices.

The most useful lesson from the project is not a feature. It is how quickly storage complexity expands.

## What it explores

The codebase touches several storage-system ideas:

- transactional KV
- page-based B+tree structures
- secondary indexes
- WAL encoding and replay
- embedded compute paths
- quorum commit experiments
- RPC schema generation
- redb and sled comparisons
- performance baselines

Each of these is reasonable on its own. Together, they create a system that needs strong boundaries to stay understandable.

## Why this is hard

Storage systems are full of cross-cutting constraints:

- write durability affects read visibility
- page layout affects compaction and recovery
- transactions affect indexing
- indexes affect write amplification
- replication affects latency and failure handling
- observability affects whether any benchmark can be trusted

It is easy to add one more subsystem and hard to know when the conceptual model has become too large.

## Documents as part of the project

One good part of `scale-kv` is that it includes design notes: API drafts, capacity models, fault drills, observability notes, and performance snapshots.

For this kind of experiment, documents are not decoration. They are the only way to keep track of what the system is supposed to prove.

## What I learned

The project reinforced a simple rule: decide what a storage experiment is testing before building the next layer.

If the goal is page structure, do not also invent distributed commit. If the goal is quorum behavior, use the simplest storage backend that can support the test. If the goal is API design, avoid mixing it with WAL recovery work.

That does not mean the project failed. It means the project taught the lesson it was supposed to teach: complexity is the main resource being spent.

## Current status

`scale-kv` is private and experimental. It may remain a lab rather than a product, which is a valid outcome for a systems project.
