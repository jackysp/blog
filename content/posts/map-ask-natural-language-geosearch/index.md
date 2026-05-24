---
title: "map-ask: Natural-Language Geospatial Search"
slug: "map-ask-natural-language-geosearch"
date: "2026-05-24T21:15:00+08:00"
draft: false
summary: "map-ask explores how plain-language map questions can become structured geospatial actions using open data sources."
description: "A project note on map-ask, a natural-language geospatial search prototype using open map data, POI search, routing, environment lookup, and weather enrichment."
categories: ["AI Tools"]
tags: ["map-ask", "geospatial", "maps", "openstreetmap", "llm"]
---

`map-ask` is a natural-language geospatial search prototype. The user asks a map question in plain English, and the system converts it into structured actions such as POI search, routing, environment lookup, or weather enrichment.

The interesting constraint is that it aims to use open data and avoid API keys where possible.

## Why maps are hard for language models

Map questions sound simple:

- find coffee near me
- show quiet parks nearby
- route to a place with shade
- find restaurants within walking distance

But those questions mix language, location, distance, categories, freshness, and user context. A language model can understand the request, but it should not invent geography.

The system needs tools.

## Open-data shape

The project uses sources such as OpenStreetMap, Nominatim, Overpass, Wikimedia REST, and related open endpoints. The map UI is built around Leaflet and React.

The model's role is to translate intent into geospatial operations:

- what is the user looking for?
- what radius or location matters?
- is this a route, POI search, or environment query?
- what enrichment should be added?

The tools then fetch actual data.

## Product boundary

The app should be honest about uncertainty. Open geospatial data is uneven. Names change, POI tags are inconsistent, and “quiet” or “hipster” are semantic hints rather than guaranteed database fields.

That means the UI should show results as interpreted matches, not absolute truth.

## What I learned

Natural-language interfaces work best when they produce inspectable structured plans. If the app can show the interpreted action, it becomes much easier to debug:

- searched category
- center point
- radius
- data source
- filters
- enrichment steps

This is especially important for maps because wrong answers can look visually convincing.

## Current status

`map-ask` is private and prototype-stage. It is safe to discuss as an architecture pattern: use an LLM for intent shaping, then rely on real geospatial tools for facts.
