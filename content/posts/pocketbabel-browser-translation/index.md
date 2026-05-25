---
title: "PocketBabel: Browser Translation Without a Backend"
slug: "pocketbabel-browser-translation"
date: "2026-05-24T08:05:00+08:00"
draft: false
summary: "PocketBabel is a small English-Chinese translation app that runs transformer models directly in the browser."
description: "A project note on PocketBabel, a frontend-only English-Chinese translation app powered by transformers.js and designed for offline reuse."
categories: ["AI Tools"]
tags: ["pocketbabel", "transformers-js", "pwa", "translation", "browser-ai"]
---

PocketBabel is a frontend-only English-Chinese translation app. It uses `@huggingface/transformers` in the browser, targets Cloudflare Pages, and is designed to keep working after the model has been downloaded and cached.

The important constraint is that there is no backend inference service. The browser is not just the UI; it is also the runtime.

## Why build it

Most translation tools are service-shaped: text goes to a server, the server runs a model, and the result comes back. That is fine for many cases, but it is also more infrastructure than I wanted for a narrow personal tool.

PocketBabel asks a smaller question: if the scope is only English to Chinese and Chinese to English, can the whole product be a static site?

That decision makes the system easier to reason about:

- no API key
- no account system
- no backend deployment
- no request logging
- no server-side scaling problem

The cost is that the first model download matters and browser performance becomes part of the product.

## Product boundary

The project intentionally avoids becoming a general translation platform. The current shape is narrow:

- English to Chinese
- Chinese to English
- text input and output
- desktop and mobile browser support
- PWA shell and offline reuse

It does not try to support OCR, speech, synced history, arbitrary language pairs, or collaborative workflows. Those features are tempting, but they would change the project from a useful small app into a maintenance surface.

## Technical shape

The implementation is a React and Vite app. Translation is handled by transformers.js with browser-side model loading and caching. Deployment is static, which makes Cloudflare Pages a natural fit.

The UI challenge is not only making a textarea and a button. The app needs to explain model state without becoming noisy:

- model not downloaded yet
- model loading
- translation running
- offline reuse available
- failure state when the browser cannot support the runtime well

For an app like this, good status text is part of the architecture. If users do not know whether the model is downloading, warming up, or stuck, the app feels broken even when the code is doing the right thing.

## What I learned

Browser AI is practical when the product scope is narrow. It is much less practical when you pretend the browser is a free replacement for a server.

The useful pattern is:

1. choose a task with a clear input and output
2. constrain the model set
3. make loading and caching behavior visible
4. avoid account and sync features unless they are essential

PocketBabel works because it does not try to be Google Translate. It is a small translation surface for a small set of language directions.

## Open source status

PocketBabel is public because the architecture is self-contained and does not rely on private infrastructure. It is also a good example of the kind of project that benefits from being inspectable: the privacy story is stronger when the code path is visible.
