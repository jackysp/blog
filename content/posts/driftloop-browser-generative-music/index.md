---
title: "driftloop: Browser Generative Music Without a Backend"
slug: "driftloop-browser-generative-music"
date: "2026-06-11T09:00:00+08:00"
draft: false
summary: "driftloop is a pure-frontend generative music app that composes and synthesizes continuous multi-instrument background music in the browser."
description: "A project note on driftloop, a browser-based generative music app using algorithmic composition, FluidSynth in WebAssembly, and optional Magenta melody generation."
categories: ["Engineering"]
tags: ["driftloop", "generative-music", "webaudio", "pwa", "music-ai"]
---

driftloop is a pure-frontend web app that streams continuous generative background music in the browser. Click play, and the music starts. Switch style buttons, and the arrangement morphs without a hard cut.

The important constraint is that every note is composed and synthesized live in the browser. There are no prerecorded loops, no server, no account, and no backend generation job.

## Why it is not mainly an AI app

The interesting origin story is that driftloop came after an earlier model-first attempt. That earlier direction tried to distill a multi-instrument music model and sample from it for the listening experience. The output was structurally chaotic in a way that sampling tweaks did not fix.

driftloop starts from a different premise: for continuous background music, structure matters more than model capacity.

Algorithmic composition handles the load-bearing parts:

- chord progression
- voice leading
- bass motion
- rhythm
- drum pattern
- section shape

A small model can still help with lead melody, but it should not be responsible for making the whole piece coherent.

## Runtime shape

The app has two layers:

1. Vanilla JavaScript composition logic that keeps the music in key, on grid, and structurally coherent.
2. An optional MelodyRNN path through TensorFlow.js for lead melody.

Synthesis uses `js-synthesizer`, a WebAssembly port of FluidSynth, with a General MIDI SoundFont through the WebAudio API.

The SoundFont is large, so deployment has a practical constraint: Cloudflare Pages has a single-file size limit smaller than the SoundFont. The app fetches the SoundFont from a public upstream mirror on first launch, then the service worker caches it for offline reuse.

## What I learned

Generative music is not only generation. It is arrangement, continuity, transitions, repetition management, and sound rendering.

The most important product question is not “is it AI?” It is “can I leave this playing without getting annoyed?” That favors simple, controllable structure over model novelty.

## Current status

driftloop is private but product-shaped. It is a static PWA candidate, and the current architecture is intentionally deployable without backend secrets or runtime infrastructure.
