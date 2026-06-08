---
title: "mood-midi-mlx: A Small MLX Loop for Symbolic MIDI Generation"
slug: "mood-midi-mlx-symbolic-generation"
date: "2026-06-12T09:00:00+08:00"
draft: false
summary: "mood-midi-mlx is a first-pass Apple MLX project for mood-conditioned symbolic MIDI generation."
description: "A project note on mood-midi-mlx, a local Apple MLX symbolic MIDI generation experiment with toy data, tokenization, training, generation, evaluation, MAESTRO import, and a small UI server."
categories: ["AI Tools"]
tags: ["mood-midi-mlx", "mlx", "midi", "music-ai", "apple-silicon"]
---

`mood-midi-mlx` is a first-pass Apple MLX project for symbolic MIDI generation. It builds a closed loop: generate or import MIDI, tokenize it, train a small decoder-only Transformer, generate tokens from mood controls, export MIDI, and evaluate the result.

It is not trying to solve music generation all at once. It is trying to make the loop inspectable.

## Why symbolic MIDI

Audio generation is expensive and hard to inspect. MIDI is smaller, structured, and easier to evaluate. For early experiments, that matters.

The project starts with controls such as:

- mood
- energy
- density
- brightness

Those controls are simple, but they are useful enough to test whether the model responds to conditioning at all.

## Training path

The first phase can generate toy piano MIDI without external datasets. It then tokenizes MIDI events, trains with MLX on Apple Silicon, and writes checkpoints plus training logs.

The repo also includes a MAESTRO import path. Since MAESTRO does not have mood labels, the importer creates heuristic weak labels from features such as tempo, density, velocity, silence, repetition, and pitch range.

That is the right level of honesty for the project: the labels are weak labels, not ground truth.

## Generation and preview

Generated tokens can be exported back to MIDI. The project also has a local UI server that can generate and download MIDI files, with an optional audio-rendering path using FluidSynth and a local SoundFont.

This makes the experiment audible without turning it into a full production app.

## What I learned

For music ML projects, the training loop is only one part of the system. The useful loop includes:

- dataset construction
- tokenization
- checkpointing
- generation controls
- structural evaluation
- audible preview

If any part is missing, it becomes hard to tell whether the model is improving or just producing plausible-looking tokens.

## Current status

`mood-midi-mlx` is private and experimental. It is a research workbench for Apple Silicon rather than a finished listening product. That separation is useful: `mood-midi-mlx` can explore models, while `driftloop` can focus on a coherent listening experience.
