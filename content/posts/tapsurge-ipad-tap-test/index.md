---
title: "TapSurge: An iPad Tap-Speed Tool Built for Competition Use"
slug: "tapsurge-ipad-tap-test"
date: "2026-05-24T08:20:00+08:00"
draft: false
summary: "TapSurge is an offline-first iPad tap-speed test that records multi-finger input with audit-friendly timing."
description: "A project note on TapSurge, a Vite and TypeScript tap-speed competition tool designed for iPad, offline use, and raw timestamp export."
categories: ["Engineering"]
tags: ["tapsurge", "ipad", "pwa", "offline-first", "typescript"]
---

TapSurge is an offline-first multi-finger click-speed test for iPad competition use. It is built with Vite, TypeScript, native DOM APIs, and Canvas.

The product sounds tiny: count taps for 10, 30, or 60 seconds. The interesting part is making that count credible.

## Why a custom tool

Most tap-speed apps are built for casual play. Competition use has different requirements:

- work offline
- run well on an iPad
- avoid accidental browser gestures
- count multi-finger input correctly
- preserve enough raw data to audit a run
- keep history locally without accounts

For this use case, simplicity matters more than visual novelty.

## Input model

TapSurge uses `pointerdown` and active pointer tracking. The key rule is that holding a finger down should not count repeatedly. A tap is a new press, not a frame, animation event, or repeated touch state.

The app records:

- total taps
- average CPS
- one-second live CPS
- maximum live CPS
- maximum simultaneous fingers
- raw timestamps and pointer IDs

That raw data is important. It lets a run be inspected after the fact instead of trusting only the final number.

## Offline design

The app is intended to work in a PWA-like mode. It has a local app shell, a service worker, and no backend dependency during play.

This is one of those projects where offline support is not a nice extra. It is part of the user story. If the tool is used at a booth, in a classroom, or during a small event, network dependency is unnecessary risk.

## UI constraints

The UI has to be obvious under pressure. A player should not be reading instructions while the timer is running.

The controls are intentionally few:

- choose duration
- start
- tap
- see result
- review history
- export evidence if needed

The harder work is preventing the browser from interfering: double-tap zoom, scroll gestures, safe-area issues, and fullscreen behavior all matter more on a real iPad than in a desktop browser.

## What I learned

Small event tools benefit from being boring. The best version is not the most animated one; it is the one that produces trustworthy results with minimal setup.

TapSurge is a good example of a private tool that could be public, but does not need a large roadmap. Its scope is the feature.
