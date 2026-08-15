---
title: "agentd: A Transport-Neutral Runtime for Personal Agents"
slug: "agentd-wasm-agent-runtime"
date: "2026-05-26T09:00:00+08:00"
lastmod: "2026-08-15T13:00:00+08:00"
draft: false
summary: "Why agentd treats turns, scoped execution, atomic finalization, and delivery as runtime contracts rather than transport details."
description: "A systems-level look at agentd, a durable single-host runtime for personal agents with scoped execution, explicit capabilities, inspectable traces, and transactional delivery."
categories: ["Infrastructure"]
tags: ["agentd", "agents", "runtime", "distributed-systems", "mcp"]
---

> **Updated August 15, 2026:** The first version of this note described an
> earlier private prototype centered on Wasm. This rewrite follows the public
> [`v0.1.0-alpha.1`](https://github.com/minifish-org/agentd/releases/tag/v0.1.0-alpha.1)
> runtime. I kept the original URL so existing links continue to work.

Most personal-agent demos begin with a chat surface: receive a message, call a
model, perhaps execute a tool, and send the answer back. That is enough to show
the interaction. It does not define what should happen when two messages arrive
for the same conversation, a process restarts, a delivery attempt times out, or
a model invokes a capability with side effects.

[`agentd`](https://github.com/minifish-org/agentd) is my attempt to put those
questions behind a small runtime contract. It is an experimental, multi-tenant,
single-agent runtime for one host. The model still decides what to do. The host
runtime owns the less glamorous parts: persistence, scheduling, scoped
serialization, capability boundaries, raw traces, and a pull delivery outbox.

The goal is not to build a universal agent framework. The narrower goal is to
make one turn durable and inspectable without coupling execution to Telegram,
a browser, a game, or any other user interface.

## The boundary starts with a turn

External systems submit work through one transport-neutral endpoint:

```text
POST /v1/tenants/:tenant/turns
```

A request identifies an agent, a scope, a payload, and optionally a delivery
destination and `request_id`. Submission returns `202` with a queued `run_id`.
The caller can wait for the canonical result, inspect the trace, cancel the run,
or consume delivery through a separate adapter.

```text
REST turn / due schedule
          |
          v
      queued run -- transactional (tenant, agent, scope) claim
          |
          v
  context -> model <-> allowed built-in/MCP tools
          |
          v
 transaction: output + terminal trace + context + optional delivery
```

This separation matters because a transport and a runtime answer different
questions. Telegram knows webhook authentication, chat identifiers, message
formatting, and Telegram's retry behavior. The runtime knows run state, context,
capabilities, and final output. Neither component needs to absorb the other's
failure model.

## Scope is both context ownership and a concurrency key

Every run moves through five states:

| State | Meaning |
| --- | --- |
| `queued` | Durable work exists but has not acquired its execution lane. |
| `running` | The run owns its `(tenant, agent, scope)` lane. |
| `succeeded` | Canonical output and related durable state were finalized. |
| `failed` | Execution ended without a successful result. |
| `cancelled` | Cancellation won and successful finalization is no longer allowed. |

The tuple `(tenant, agent, scope)` is the serialization boundary. Runs for the
same tuple execute one at a time; unrelated scopes can run concurrently. The
claim is transactional, and the database also enforces that at most one run for
a scope is `running`.

Using scope for both rolling context and serialization is deliberate. If two
turns can modify the same conversation history concurrently, the runtime needs
a merge policy or a clear winner. `agentd` avoids inventing one: a scope has one
active owner. A Telegram chat can use `tg:<chat_id>`; a game can use a match and
seat identifier; another caller can define a different stable boundary.

This is not distributed locking. It is single-database coordination for one
host. There is no multi-process lease protocol, failover, or replication claim.

A process restart also has an explicit, conservative outcome. On startup,
persisted runs that were `running` become `failed` with an `agentd restarted`
error, while durable queued work remains available to the dispatcher. The
runtime does not try to reconstruct the interrupted model/tool loop or silently
execute it again. That avoids pretending an in-flight external effect is safe to
repeat, at the cost of requiring a caller or operator to decide whether a failed
turn should be resubmitted. More sophisticated recovery would need an explicit
side-effect protocol, not just a different status update.

## Submission idempotency is not replay

An optional `request_id` is unique within a tenant. Repeating the same
submission returns the existing run instead of creating another one. This is
useful when an HTTP client cannot tell whether its first request succeeded.

But request deduplication does not make the whole agent execution replayable.
During a run, the model can call tools, an MCP server can affect another system,
and a transport can deliver a message. Those effects do not become reversible
because the initial request had an idempotency key.

The raw `run_log` records model, tool, output, status, and error observations.
It is an inspection trace, not a deterministic re-execution engine. There is no
side-effect ledger, rollback protocol, or replay simulator. Calling these
different properties by different names prevents a comforting but false
exactly-once story.

## The model chooses; the host constrains

An agent is configuration rather than executable plugin code: persona, model,
allowed capability families, limits, temperature, token budget, and context
window. The native loop sends visible schemas to an OpenAI-compatible provider,
validates the returned tool call, executes it in host code, records the result,
and continues until the model produces final JSON or reaches a boundary.

The public alpha has 15 built-in capabilities across artifacts, memory,
schedules, clock, bounded public-web access, and arithmetic. It intentionally
has no generic shell, arbitrary HTTP request, hidden filesystem handle, approval
queue, or operator execute endpoint.

MCP extends the tool catalog without changing that ownership model. Servers
belong to a tenant, discovery is explicit, exposed names must be unique, and an
allowlist can narrow the discovered catalog. Secret configuration stores the
names of environment variables rather than their values.

That is a capability boundary, not a sandbox. An operator-configured stdio MCP
process runs with the `agentd` OS user's host and network permissions. A model
can also be persuaded by a malicious prompt or tool result to call any capability
it can see. The safe rule is therefore simple: expose only side effects that are
acceptable without human approval, and isolate untrusted MCP servers outside
the runtime.

## Successful finalization has one transaction boundary

The most important write path happens after the model loop has produced a
successful result. One database transaction commits:

- the canonical output and `succeeded` run status;
- the terminal trace event;
- the bounded rolling context;
- and, when explicitly requested, one pending delivery referencing the run.

If cancellation has already changed the run state, successful finalization is
rejected. A cancelled run cannot leave behind successful output, updated
context, or a delivery row. A second finalization is rejected as well.

This transaction does not roll back external tool effects that occurred before
it. Its guarantee is narrower: readers do not observe a successful run whose
output, terminal trace, context, and delivery intent disagree with one another.
That is the consistency boundary the runtime can actually own.

## Delivery is durable intent, not a callback hidden in execution

Every successful result is pullable. Delivery exists only when the caller
provides an explicit destination such as `tg:42`; scope is never silently
treated as an address.

```text
Telegram -> webhook -> turn with explicit tg:<chat_id> destination
agentd    -> atomic run finalization -> delivery outbox
adapter   -> claim -> Telegram API -> acknowledge
```

Delivery rows reference the run instead of copying its output. An adapter
claims pending work with a random token and expiry, performs the remote side
effect, and acknowledges one of `delivered`, `retry`, or `failed`. An expired
claim can be issued again; a retry updates the same row rather than inserting a
new delivery.

The independent
[`agentd-telegram-adapter`](https://github.com/minifish-org/agentd-telegram-adapter)
uses exactly this interface. Its webhook path submits a turn and asks for an
explicit Telegram destination. It does not send a direct reply from the webhook
handler and does not fall back to polling run output as a second delivery path.
This removes two easy sources of duplicate messages.

The outbox still cannot prove that a remote system performed an effect if the
adapter crashes before acknowledgement. Claim expiry and retry make recovery
possible; they do not manufacture exactly-once semantics from an external API.

## State is separated by meaning, not by service count

The runtime uses one libSQL database. The schema separates responsibilities:

- runs own activation, status, canonical output, and requested destination;
- `run_log` owns raw execution observations;
- contexts own recent messages for a scope;
- memory owns explicit durable facts plus lexical and semantic indexes;
- artifacts own larger payloads;
- deliveries own remote-delivery state and retry fields;
- schedules and MCP registrations remain tenant-scoped resources.

This is intentionally less infrastructure than earlier prototypes. There is no
separate object store, vector service, audit database, or replay database. The
memory implementation keeps canonical text, an FTS5 index, and a pinned
384-dimension E5 embedding together; lexical and semantic ranks are fused with
RRF.

The trade-off is equally explicit: this pre-1.0 runtime does not preserve schema
or HTTP compatibility. Runtime data is treated as disposable. A schema mismatch
requires `--reset-data`, not a migration. That is acceptable for the current
personal-runtime scope, but it would not be an acceptable default for a mature
multi-user platform.

## Design claims should point to executable evidence

The repository includes a
[`reliability matrix`](https://github.com/minifish-org/agentd/blob/main/docs/reliability.md)
that maps each important property to a named test. The current suite covers
tenant-scoped request deduplication, same-scope serialization, failed-agent lane
release, atomic finalization, cancellation races, pull-only success, delivery
reclaim and acknowledgement, MCP scoping, public-web network boundaries, memory
scoping, schema mismatch, and non-loopback authentication requirements.

There is also a credential-free deterministic demo:

```sh
git clone https://github.com/minifish-org/agentd.git
cd agentd
./scripts/demo-e2e.sh
```

It starts a loopback OpenAI-compatible fixture, starts `agentd` with a fresh
database, creates a tenant and agent, submits a turn, waits for the result,
inspects the trace, verifies pull-only behavior, and exercises artifact storage.
The first run downloads about 448 MiB of revision- and checksum-pinned embedding
assets.

The fixture proves the documented runtime and API path. It does not prove model
quality, real-provider tool compatibility, prompt-injection resistance,
streaming behavior, or production latency. The release workflow separately runs
the real embedding smoke test and builds and inspects the complete container
image.

## The gaps are part of the design document

The public alpha does not claim evidence for:

- process-kill fault injection at every transaction boundary;
- multi-process or multi-host coordination, failover, or replication;
- compatibility across database schema or HTTP versions;
- load, soak, latency, quota, or denial-of-service limits;
- deterministic replay or rollback of external tool effects;
- sandboxing of operator-configured MCP processes;
- behavior against every provider, MCP server, or transport adapter;
- model safety or factual correctness.

Its bearer token is an instance-wide operator credential, not end-user
authentication. Tenants provide resource namespaces; they do not isolate
mutually distrustful users who share that token. TLS termination, rate limits,
backups, and host-level resource isolation remain deployment responsibilities.
The full boundary is documented in the
[`threat model`](https://github.com/minifish-org/agentd/blob/main/docs/threat-model.md).

Publishing these gaps is useful because an experimental system is easiest to
overstate precisely where its tests end. A reliability matrix should show both
the properties under test and the empty cells.

## What building it changed for me

My distributed-database background makes me look for ownership, monotonic
boundaries, and failure states before adding features. `agentd` applies those
habits at a smaller scale:

1. A conversation scope needs an execution owner, not just a string in a prompt.
2. Idempotent submission, deterministic replay, and external-effect recovery are
   separate problems.
3. Successful output is not complete until related durable state agrees at one
   transaction boundary.
4. Transport integration belongs outside the runtime, but its delivery intent
   must still participate in finalization.
5. A tool catalog is a security boundary only when the host validates it and the
   deployment respects what the host cannot isolate.
6. Tests and explicit omissions are stronger project documentation than a long
   feature list.

`agentd` remains experimental. It is not a general workflow engine, an HA agent
platform, or a sandbox for untrusted code. It is a public attempt to make one
personal-agent turn durable, scoped, inspectable, and deliverable—and to state
precisely where those guarantees stop.

Source, release notes, and the reproducible demo are available in the
[`minifish-org/agentd`](https://github.com/minifish-org/agentd) repository under
Apache-2.0.
