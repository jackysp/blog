---
title: "Tailgate: A Private AI Gateway for Local and Remote Models"
slug: "tailgate-private-ai-gateway"
date: "2026-05-24T08:10:00+08:00"
draft: false
summary: "Tailgate is my private OpenAI-compatible gateway for routing AI clients across local and hosted providers."
description: "A project note on tailgate, a private AI gateway that centralizes model routing, secrets, provider selection, and local model integration."
categories: ["AI Tools"]
tags: ["tailgate", "ai-gateway", "openai-compatible", "local-llm", "tailscale"]
---

Tailgate is a personal OpenAI-compatible AI gateway. It gives tools like Codex, Cursor, SDK clients, and local agents one private `base_url`, while provider keys and routing rules stay on a server I control.

It is not meant to be a public model marketplace. The point is not to replace OpenRouter or any other provider. The point is to make my own AI workflow less scattered.

## The problem

Once you use multiple model providers, the configuration spreads quickly:

- local model endpoint
- hosted model provider keys
- fallback behavior
- model names
- pricing assumptions
- tool-specific environment variables
- different capabilities for chat, embeddings, speech, and transcription

Every client wants a slightly different setup. That is annoying for normal use and worse for agents, because agent configuration should be boring and repeatable.

Tailgate puts that complexity behind one OpenAI-compatible surface.

## Design shape

The core API follows familiar endpoints:

- `GET /v1/models`
- `POST /v1/chat/completions`
- `POST /v1/embeddings`
- `POST /v1/audio/speech`
- `POST /v1/audio/transcriptions`

Behind that surface, the gateway can route requests to local `qwen-local`, DeepSeek, OpenRouter, or future compatible providers. It tracks provider health, supports streaming passthrough, and can apply simple route selection rules.

The most useful rule is not fancy AI logic. It is policy:

- prefer local when the task fits
- keep secrets off client machines
- avoid sending private work to external providers accidentally
- fall back only when the route explicitly allows it

## From a private deployment to public code

Tailgate started with assumptions about my own environment: private networking, provider credentials, model preferences, and operational defaults. On September 22, 2026, I opened the [repository](https://github.com/minifish-org/tailgate) after generalizing the setup examples and documenting the supported Rust runtime. Credentials and live deployment configuration stay outside the repository.

The running gateway remains a private service. The reusable part is the policy boundary: centralized credentials, explicit routing, and protection for local inference.

## What I learned

The biggest value of a gateway is not only key management. It is reducing mental overhead.

Before the gateway, every tool needed to know too much. After the gateway, tools only need:

- one base URL
- one API key or private network policy
- normal OpenAI-compatible request shapes

That makes experiments cheaper. I can change the provider map without editing every client.

The second lesson is that local models need protection. A small local model service may only handle one heavy inference at a time. A gateway can enforce concurrency and fallback rules so clients do not accidentally overload the local runtime.

## June 2026 update

The pushed version has a clearer premium route. `premium/chat` now prefers the configured DeepSeek premium model before falling back to the configured OpenRouter premium model. Config order is also used as a tiebreaker when candidates have the same price ranking, which keeps routing behavior predictable instead of surprising.

This is a good example of the gateway's real job: not to be clever, but to make model policy explicit. A client can ask for `premium/chat`; Tailgate decides which concrete upstream model should satisfy that tier.

## Current status

As of September 22, 2026, [Tailgate is public](https://github.com/minifish-org/tailgate) under AGPL-3.0-only. The repository includes a localhost-first configuration, Rust setup instructions, automated tests, and secret scanning. It remains an experimental self-hosted gateway; operators supply their own inference endpoints and provider accounts.
