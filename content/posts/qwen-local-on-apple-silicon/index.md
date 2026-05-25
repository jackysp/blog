---
title: "qwen-local: Running an OpenAI-Compatible Model Service on Apple Silicon"
slug: "qwen-local-on-apple-silicon"
date: "2026-05-24T08:15:00+08:00"
draft: false
summary: "qwen-local is a thin FastAPI service around MLX models for chat, embeddings, text-to-speech, and speech-to-text on a 16 GB Mac."
description: "A project note on qwen-local, a local OpenAI-compatible AI service for Apple Silicon using MLX, Qwen, Kokoro, and Whisper."
categories: ["AI Tools"]
tags: ["qwen-local", "mlx", "apple-silicon", "openai-compatible", "local-llm"]
---

`qwen-local` is an OpenAI-compatible local model service for a 16 GB Apple Silicon Mac. It wraps local MLX models behind a FastAPI service and exposes chat, embeddings, text-to-speech, and speech-to-text through one local endpoint.

The idea is simple: keep local inference usable by normal OpenAI SDK clients.

## Why this exists

Local models are most useful when they can plug into existing tools. A model that only works through a special command is interesting, but a model that looks like an OpenAI-compatible service can be used by editors, agents, scripts, and gateways.

That is the purpose of `qwen-local`. It is not a model research project. It is an adapter and runtime boundary.

The default shape is:

- MLX for Apple Silicon inference
- Qwen for chat
- Qwen embeddings
- Kokoro for text-to-speech
- MLX Whisper for speech-to-text
- one `/v1` API surface

Once models are cached, inference should not require external API calls.

## The useful constraint: 16 GB

The project targets a realistic personal machine rather than a workstation with huge memory. That constraint forces decisions:

- prefer quantized models
- keep concurrency conservative
- avoid loading every capability eagerly if it hurts responsiveness
- make stuck inference and runtime locks visible

Local AI services fail in different ways from hosted APIs. A hosted provider returns rate-limit errors or provider errors. A local process can get memory pressure, model load stalls, file cache problems, or long single-user queues.

That makes operational behavior part of the product.

## Relationship to tailgate

`qwen-local` is the local model service. Tailgate is the gateway that decides when to use it.

Keeping those roles separate matters. The local service should focus on model loading, request compatibility, and media endpoints. The gateway can handle policy, provider selection, fallback, and external clients.

That split keeps `qwen-local` from becoming a general AI router.

## What I learned

OpenAI-compatible does not mean full OpenAI clone. The useful target is compatibility for the clients I actually use:

- chat completions
- embeddings
- speech generation
- transcription
- predictable model IDs
- normal error shapes where possible

The second lesson is that local inference needs a health model. It is not enough to expose an endpoint. I need to know whether the service is loaded, busy, stuck, or unavailable, especially when another tool is routing requests into it.

## Open source status

This project is private because it includes local operational assumptions and is tuned for my own machine. The general pattern is public enough to discuss: make local models boring by putting them behind familiar API contracts.
