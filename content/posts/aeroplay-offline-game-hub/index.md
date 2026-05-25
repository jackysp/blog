---
title: "AeroPlay: A Flight-Mode Game Hub"
slug: "aeroplay-offline-game-hub"
date: "2026-06-03T09:00:00+08:00"
draft: false
summary: "AeroPlay is a mobile-first offline game hub designed to work in airplane mode with local assets and saved progress."
description: "A project note on AeroPlay, a pure frontend offline game hub with mini games, localStorage progress, service worker caching, and add-to-home-screen support."
categories: ["Engineering"]
tags: ["aeroplay", "offline-first", "pwa", "games", "typescript"]
---

AeroPlay is a pure-frontend, mobile-first game hub optimized for flight-mode use. It includes small games like Snake, Tetris, 2048, Flappy Bird, Maze, Match-3, Sudoku, and Lights Out.

The whole point is that it should keep working with no network.

## Why build it

Airplane mode is a useful product constraint. It removes a lot of lazy assumptions:

- no backend calls
- no CDN dependency during play
- no login
- no remote save
- no ads
- no analytics requirement

What remains is the app itself: local assets, local state, and games that are worth playing in short sessions.

## Template shape

AeroPlay is also designed as a template. The repo can be used to bootstrap another offline game hub without carrying old issues or unrelated history.

That makes the project more useful than a single app. It becomes a base pattern:

- Vite and TypeScript
- local game modules
- service worker
- manifest
- `localStorage` progress
- mobile-first layout

## Product boundary

The project should not become a general gaming platform. Its strength is the opposite: a small set of local games, predictable input, and no network requirement.

For this kind of app, “more features” can easily make the experience worse. If the user opens it in flight mode, the app should not show half-broken online features.

## What I learned

Offline-first is easiest when it is a requirement from the beginning. Retrofitting offline behavior onto an app that assumed servers and remote assets is much harder.

AeroPlay also shows that simple games still need polish:

- touch controls
- stable layout
- saved state
- fast startup
- no accidental scroll
- clear pause and restart behavior

Those details matter more on a phone than in a desktop demo.

## Open source status

AeroPlay is public because it is self-contained, harmless to share, and useful as a template. It is a good example of a small project whose constraints make it more reusable.
