---
title: "Nightfall: A Browser Referee for AI Werewolf"
slug: "nightfall-ai-werewolf-referee"
date: "2026-06-10T09:00:00+08:00"
draft: false
summary: "Nightfall is a web-based AI Werewolf platform where the browser is the referee and agentd supplies the AI seats."
description: "A project note on Nightfall, an AI Werewolf prototype with a browser referee, projected per-seat views, an agentd-backed turn API, and a shared engine for CLI and UI runs."
categories: ["AI Tools"]
tags: ["nightfall", "agents", "game-ai", "werewolf", "react"]
---

Nightfall is a web-based AI Werewolf platform. Every seat is an AI player; the human is an operator or spectator. The browser is the referee.

That referee boundary is the most important design choice. The game engine holds the authoritative state and decides what each seat is allowed to see. The AI players only receive projected views.

## Why the browser is the referee

Werewolf is an information game. The system must know the full state, but each player must see only a slice of it. If the AI seat receives hidden information by accident, the whole experiment is meaningless.

Nightfall keeps that boundary explicit:

- `engine/` owns state, phase transitions, view projection, resolution, victory checks, and deterministic replay
- `orchestrator/` runs the environment-independent game loop
- `agentd-client/` calls `POST /v1/turns`
- `app/` renders the spectator UI without owning game rules

The same engine can drive a Node CLI transcript or the browser spectator.

## agentd integration

Nightfall does not embed agent logic. It calls an external `agentd` runtime. The werewolf, seer, and villager agents live on the agentd side as personas and model choices. Nightfall only maps roles to `agent_ref` values and sends the projected view for the current seat and phase.

That separation matters. The game should own rules; agentd should own agent execution.

## Game shape

The current board is intentionally small:

- 6 seats
- 2 wolves
- 1 seer
- 3 villagers
- no role reveal on death
- loop: night seer, night wolf, day discussion, day vote

Victory is checked after deaths: wolves eliminated means good wins; all villagers dead means wolves win. Killing the seer does not end the game, it only removes the good side's information source.

## What I learned

Games are useful agent testbeds because they force state discipline. A chat bot can hide vague behavior behind language. A game cannot. The engine needs phases, legal actions, projected views, victory rules, and reproducible transcripts.

Nightfall is also a reminder that a good agent integration is often just a clean boundary. The AI seat should not know the whole game. It should know what that player would know.

## Current status

Nightfall is private and experimental. It is useful as an AI interaction lab, especially for testing information hiding, role-specific personas, and multi-agent turn orchestration.
