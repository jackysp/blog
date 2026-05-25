---
title: "agentd: A Wasm-Native Harness for Personal Agents"
slug: "agentd-wasm-agent-runtime"
date: "2026-05-26T09:00:00+08:00"
draft: false
summary: "agentd is an experimental single-host control plane for running Wasm-native agents with explicit host capabilities."
description: "A project note on agentd, a Wasm-native single-host agent harness with host capabilities for messaging, schedules, memory, artifacts, web access, and LLM calls."
categories: ["AI Tools"]
tags: ["agentd", "agents", "wasm", "wasmtime", "runtime"]
---

`agentd` is a Wasm-native single-host agent harness and control plane. It is an experiment in making small personal agents run behind explicit host capabilities instead of giving every agent direct access to the whole machine.

The current direction separates three layers:

- Wasm agent components
- native host capability facade
- backend execution adapters

That shape is more important than any single feature.

## Why Wasm

Agent code can become messy quickly. It wants tools, memory, context, schedules, datasets, artifacts, web access, and LLM calls. If everything is just native code with direct access, boundaries blur.

Wasm gives the project a useful constraint: agent logic runs in a sandboxed component and reaches the outside world through capabilities.

That makes the runtime ask better questions:

- what can this agent do?
- which tools are stable host APIs?
- what state belongs to the host?
- what should be passed into a run?
- what should be persisted after a run?

## Capability surface

The active design exposes host-facing capabilities such as:

- `im.*`
- `run.*`
- `schedule.*`
- `dataset.*`
- `artifact.*`
- `memory.*`
- `context.*`
- `web.*`
- `clock.*`
- `llm.*`

This is deliberately explicit. Instead of an agent inventing arbitrary side effects, it asks the host for specific operations.

## Example app

The repo includes a minimal Telegram bot app. It uses an `agentd`-backed Telegram session runtime, provider integration, memory/context handling, artifacts, schedules, and messaging.

The interesting part is not that it can reply to Telegram. The interesting part is that a chat turn becomes an agent run with a lane, scope, memory policy, and host-managed capabilities.

## What I learned

Agents need less magic and more runtime discipline. A personal bot is still a distributed system in miniature:

- messages arrive concurrently
- context scopes matter
- retries can duplicate work
- memory needs indexing and pruning
- tools need permission boundaries
- failures need artifacts and logs

The Wasm boundary helps keep those concerns visible.

## Current status

`agentd` is experimental and private. It is useful as a lab for runtime shape, but I do not consider it a public platform yet. The public lesson is the architecture: put capabilities between agents and the host before the tool surface grows without control.
