---
title: "agentd: A Transport-Neutral Runtime for Personal Agents"
slug: "agentd-wasm-agent-runtime"
date: "2026-05-26T09:00:00+08:00"
draft: false
summary: "agentd is an experimental single-host runtime where agents are driven through a transport-neutral turn API and explicit host capabilities."
description: "A project note on agentd, a single-host agent runtime with a transport-neutral turn API, a built-in generic agent, SeekDB-backed state, and explicit host tools."
categories: ["AI Tools"]
tags: ["agentd", "agents", "runtime", "mcp", "seekdb"]
---

`agentd` is a single-host agent runtime and control plane. Its current shape is transport-neutral: external systems drive agents through `POST /v1/turns`, then read results back through the run output API. The runtime owns state, tools, scheduling, memory, artifacts, and the generic agent loop.

That is a different direction from the first version of this note, which described `agentd` mainly as a Wasm-native harness. The pushed version is now more concrete: an `Agent` is a manifest with a system prompt, visible tool catalog, resource limits, and a model choice. The actual handler is the built-in generic agent.

## Turn API

A caller submits:

```text
POST /v1/turns
```

with a tenant, `agent_ref`, scope, and payload. The runtime creates an `AgentRun`, resolves a lane, assembles the visible tools, invokes the generic agent, and records a structured `final_decision`.

There is no push side. A Telegram bot, a browser game, or another transport bridge should call the API and render the result itself. That keeps `agentd` from becoming coupled to a specific messaging system.

## Capability surface

The current public tool surface includes:

- `plan.*`
- `run.*`
- `schedule.*`
- `artifact.*`
- `memory.*`
- `context.*`
- `web.*`
- `clock.*`
- `llm.*`
- `output.*`

The important pattern is that tools carry reliability metadata: maturity, idempotency, side-effect scope, failure classes, replay expectations, and delivery semantics. That metadata is part of making agent behavior inspectable instead of magical.

## Storage model

Durable state now lives in SeekDB, a MySQL-compatible OceanBase-derived database. Control-plane state, context, artifacts, and memory all use that one database boundary. Memory is per tenant and uses native vector plus full-text retrieval.

This is a pragmatic simplification. There is no MinIO, S3, Litestream, or separate object store in the core path.

## What I learned

Agents need less magic and more runtime discipline. Even a personal agent runtime has to answer boring operational questions:

- context scopes matter
- retries can duplicate work
- memory needs indexing and pruning
- tools need permission boundaries
- failures need artifacts and logs
- callers need a stable way to wait for output

The useful boundary is no longer just Wasm. It is the turn contract plus explicit host capabilities.

## Current status

`agentd` is experimental and private. It is useful as a lab for runtime shape, but I do not consider it a public platform yet. The public lesson is the architecture: keep transports outside the core runtime, keep tool capabilities explicit, and make every run produce inspectable output.
