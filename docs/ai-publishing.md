# AI Publishing Contract for jackysp/blog

This document defines the ONLY allowed way for AI agents
to publish content into this repository.

## Scope
- This repository is a Hugo blog source repo.
- Build artifacts are published by GitHub Actions to
  https://github.com/jackysp/jackysp.github.io

## Allowed modifications
AI agents MAY ONLY modify or create files under:
- content/**
- static/**

Any modification outside these paths is STRICTLY FORBIDDEN.

## Post location
- All blog posts MUST be placed under:
  content/posts/

## Post format
- Hugo front matter format: YAML
- Required fields:
  - title
  - date (RFC3339 with timezone +08:00)
  - draft (boolean)
  - tags (array of strings)
  - slug
  - summary

## File naming
- Preferred: content/posts/YYYY-MM-DD-slug.md
- Or: content/posts/slug.md

## Images
- Preferred: Page Bundle:
  content/posts/slug/index.md
  content/posts/slug/*.png
- Or static images under:
  static/img/YYYY/MM/

## Commit rules
- Target branch: default branch only
- One commit per post
- Commit message:
  "Publish: <post title>"

## Prohibited actions
- Do NOT modify themes, workflows, configs, or dependencies
- Do NOT delete existing posts
- Do NOT touch build output repositories
