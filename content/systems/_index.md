---
title: "Systems"
description: "Selected writing on distributed systems, reliable agent execution, and inference infrastructure."
disableAnchoredHeadings: true
menu:
  main:
    name: "Systems"
    weight: 5
---

This is the shortest path through my systems work. The three threads share a
common concern: making state, ownership, failure, and resource boundaries
explicit enough to reason about.

## Distributed Systems

### [How to Read TiDB Source Code](/posts/how-to-read-tidb-source-code-part-1/)

A five-part path through TiDB's server lifecycle, SQL execution, transaction
handling, and supporting subsystems:
[Part 1](/posts/how-to-read-tidb-source-code-part-1/),
[Part 2](/posts/how-to-read-tidb-source-code-part-2/),
[Part 3](/posts/how-to-read-tidb-source-code-part-3/),
[Part 4](/posts/how-to-read-tidb-source-code-part-4/), and
[Part 5](/posts/how-to-read-tidb-source-code-part-5/).

The series was written against the 2020 source tree. Its reading method remains
useful, but individual code paths and package names may have changed.

### [How TiDB Implements the INSERT Statement](/posts/how-tidb-implements-the-insert-statement/)

A code-level walk through planning and executing one of the most common SQL
write paths.

### [OceanBase Internals: Transactions, Replay, SQL Engine, and Unit Placement](/posts/oceanbase-internals-transaction-replay-sql-unit-placement/)

A map of how transaction processing, recovery, query execution, and resource
placement meet inside a distributed database.

## Agent Systems

### [agentd: A Transport-Neutral Runtime for Personal Agents](/posts/agentd-wasm-agent-runtime/)

An architecture note on turn contracts, explicit capabilities, durable state,
scoped execution, atomic finalization, and delivery. `agentd` is an
[experimental public alpha](https://github.com/minifish-org/agentd), with
executable reliability evidence and explicit limits.

### [Running OpenAI Symphony as a Solo Development System](/posts/symphony-solo-dev-blog/)

What changes when an agent workflow is treated as an operating system for work
rather than a collection of prompts.

### [Tailgate: A Private AI Gateway](/posts/tailgate-private-ai-gateway/)

A smaller project note about centralizing provider access, policy, and
observability at an AI gateway boundary.

## Inference Systems

This is the newest part of the portfolio. The current public notes document
hands-on serving experiments; scheduler, cache, routing, and performance work
will be added only when it has reproducible code or measurements.

### [Qwen Local on Apple Silicon](/posts/qwen-local-on-apple-silicon/)

A practical local-serving setup and the operational constraints that surfaced
while running a model on consumer hardware.

### [Exploring Local LLMs with Ollama](/posts/exploring-local-llms-with-ollama-my-journey-and-practices/)

An earlier field note on local model serving and application integration.

## Projects and Code

- [TiDB contributions](https://github.com/pingcap/tidb/pulls?q=is%3Apr+author%3Ajackysp+is%3Amerged)
- [GitHub profile](https://github.com/jackysp)
- [Minifish Lab](https://github.com/minifish-org)

I keep exploratory tools and personal projects elsewhere on the blog. This page
is intentionally narrower: it collects the work most relevant to distributed
systems and AI infrastructure.
