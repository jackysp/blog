---
title: "Canopy: Local MCP Routing for Singapore PCN Loops"
slug: "canopy-singapore-pcn-routing"
date: "2026-06-09T09:00:00+08:00"
draft: false
summary: "Canopy is a local MCP server for Singapore cycling and walking routes, using GraphHopper with a PCN-biased model and OneMap for geocoding."
description: "A project note on Canopy, a self-hosted MCP routing service for Singapore cycling and walking route planning with GraphHopper, OneMap, GPX export, and route audits."
categories: ["AI Tools"]
tags: ["canopy", "mcp", "singapore", "cycling", "graphhopper"]
---

Canopy is a local MCP server for Singapore cycling and walking route planning. It is built for agents, not for end users. Claude, Codex, LangChain, or another MCP client can call Canopy tools; the agent remains responsible for conversation and presentation.

The useful distinction is that Canopy does not try to be a map app. It is a route-planning capability.

## Why this exists

Singapore cycling routes are not only about shortest path. A good route often means:

- prefer PCN-like paths
- avoid high-car roads
- keep loops close to a target distance
- export a track that can be followed elsewhere
- explain how much of the route is car-free or on-road

General routing APIs are not always good at expressing those preferences. Canopy uses a self-hosted GraphHopper service with a custom bike profile that strongly prefers cycleways, PCN-like paths, and low-car links while penalizing motor roads.

OneMap is used for geocoding and POIs, not routing.

## Tool surface

The MCP server exposes tools such as:

- `geocode(query)`
- `plan_loop(start, distance_km, direction?, prefer="pcn")`
- `route(origin, destination, prefer="pcn")`
- `pois_along(geometry, types=[...])`
- `audit_route(geometry)`
- `export_gpx(geometry, name)`

That gives an agent a clean workflow: resolve a place, plan a route, audit the result, find POIs along the corridor, and export GPX.

## Honest boundaries

Canopy optimizes for low-car and away-from-traffic routing. It does not avoid pedestrians, because Singapore PCNs are shared paths.

Round-trip distance is also approximate in GraphHopper. Canopy tries multiple seeds and scaled requests, then returns the actual distance instead of pretending the target was exact.

The project also intentionally avoids building turn-by-turn navigation. A downstream app can load the generated GPX track into something like OsmAnd or CoMaps.

## What I learned

MCP is a good fit when the tool is specific and verifiable. Route planning should not be hidden inside a chat answer. The agent should call a tool that returns geometry, distance, audit percentages, and a GPX path.

For location work, the agent's job is orchestration. The route engine should still be a route engine.

## Current status

Canopy is private and active. It is tied to local Singapore routing data, OneMap credentials, and a local GraphHopper runtime, so the repo is not a clean general-purpose hosted service.
