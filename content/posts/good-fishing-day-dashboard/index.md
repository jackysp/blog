---
title: "good-fishing-day: A Fishing Weather Dashboard"
slug: "good-fishing-day-dashboard"
date: "2026-05-24T09:20:00+08:00"
draft: false
summary: "good-fishing-day is a small personal dashboard that combines tide and weather data to estimate whether a day is worth fishing."
description: "A project note on good-fishing-day, a Cloudflare Workers and Astro dashboard that combines tide, weather, caching, and a simple fishing suitability score."
categories: ["Field Notes"]
tags: ["fishing", "weather", "cloudflare-workers", "astro", "personal-dashboard"]
---

`good-fishing-day` is a personal fishing-weather dashboard. It combines tide data and weather forecasts to answer a practical question: is today, or the next few days, good for fishing?

It is a small application, but it has the shape of a real product: backend data fetching, caching, scoring, frontend display, and deployment.

## Why build it

Fishing decisions depend on several signals:

- tide timing
- weather
- wind
- rain
- forecast window
- saved locations

Generic weather apps show the raw pieces, but they do not answer the combined question I care about. A personal dashboard can make that tradeoff directly.

## Architecture

The backend is a Cloudflare Worker. It fetches marine/tide data and weather forecasts, computes a score, and caches results in Workers KV.

The frontend is an Astro and React app deployed to Cloudflare Pages. Shared TypeScript code keeps constants and data shapes aligned.

This is a good fit for Cloudflare because the workload is small, read-heavy, and cacheable.

## Privacy and scope

The app is intentionally personal and ad-free. It does not need accounts, social features, or public rankings. It needs to answer a small question reliably.

The main external dependency risk is data quality and API availability. That makes caching and clear failure states important.

## What I learned

Personal dashboards are worth building when they compress repeated decision-making. The value is not that the app is complicated. The value is that it turns several tabs and mental calculations into one screen.

The scoring model should also stay humble. A “good fishing day” score is a decision aid, not a guarantee. The app should make the inputs visible enough that I can override the score with judgment.

## Current status

`good-fishing-day` is private because it is tied to personal usage and deployment details. The architecture pattern is reusable: small Worker backend, cached external data, static frontend, and a domain-specific score.
