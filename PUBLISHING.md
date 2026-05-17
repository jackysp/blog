# Publishing Contract for MCP Agents

⚠️ **This document is specifically for MCP-based publishing workflows.**

This contract defines STRICT restrictions for AI agents publishing content via MCP (Model Context Protocol). These restrictions are more limited than general agent guidelines to ensure repository safety.

**For general project guidelines**, see `AGENTS.md` (if exists).

---

This document defines the ONLY allowed way for AI agents to publish content into this repository via MCP.

## Scope

- This repository is a Hugo blog source repo.
- Build artifacts are published by GitHub Actions to
  <https://github.com/jackysp/jackysp.github.io>

## Allowed modifications

AI agents MAY ONLY modify or create files under:

- content/**
- static/**

Any modification outside these paths is STRICTLY FORBIDDEN.

## Post location

- All blog posts MUST be placed under:
  content/posts/<slug>/index.md
- Each post MUST use a Hugo Page Bundle directory named after the post slug.

## Post format

- Hugo front matter format: YAML
- Required fields:
  - title (string)
  - date (RFC3339 format with timezone +08:00, e.g., "2026-01-17T10:00:00+08:00")
  - draft (boolean: true for drafts, false for published posts)
  - summary (string)
  - description (string)
  - categories (array of strings)
  - tags (array of strings)
  - slug (string, URL-friendly identifier)

### Front matter example

```yaml
---
title: "Your Post Title"
date: "2026-01-17T10:00:00+08:00"
draft: false
summary: "A short, concrete summary of the post."
description: "A one-sentence description for search, sharing, and archive pages."
categories: ["Engineering"]
tags: ["tag1", "tag2", "tag3"]
slug: "your-post-slug"
---
```

### Slug format rules

- Use lowercase letters, numbers, and hyphens only
- No spaces or special characters
- Keep it concise and descriptive
- Example: "oceanbase-internals-transaction-replay" (not "OceanBase Internals: Transaction Replay")

## File naming

- **Required format**: `content/posts/slug/index.md`
- Use only the slug (lowercase letters, numbers, and hyphens) as the bundle directory name
- Do NOT include date prefix in filename (date is already in front matter)
- Example: `content/posts/ai-mcp-blog-publishing-workflow/index.md` (not `content/posts/2026-01-19-ai-mcp-blog-publishing-workflow/index.md`)

## Images

### Image storage location

- **All post images MUST be placed in the same bundle directory as the post:** `content/posts/<slug>/`

### Image reference format

- Reference images in markdown using a relative filename: `filename.ext`
- Example: `![alt text](20241210_093935_image.webp)`

### Image naming conventions

- Use descriptive filenames with timestamps or meaningful names
- Supported formats: `.png`, `.jpg`, `.jpeg`, `.JPG`, `.gif`, `.webp`
- Examples:
  - `20241210_093935_image.jpg` (timestamp-based)
  - `screenshot-diagram.png` (descriptive)

### Image usage in posts

```markdown
![Image description](filename.webp)
```

### Image best practices

- Use descriptive alt text for accessibility
- Optimize images before uploading (reasonable file sizes)
- Maintain consistent naming patterns
- Keep each image at or below 1 MiB
- Remove EXIF metadata from privacy-sensitive JPEG photos before publishing
- Do not commit unused images; every image in a post bundle must be referenced by that post

## Draft vs Published workflow

- Set `draft: true` for posts that are not ready for publication
- Set `draft: false` for posts ready to be published
- Published posts (`draft: false`) will appear on the live site
- Draft posts (`draft: true`) are excluded from the build output

## Content structure

- Use standard Markdown syntax for content
- Headers: Use `##` for main sections, `###` for subsections
- Code blocks: Use triple backticks with language identifiers
- Lists: Use `-` for unordered lists, numbered for ordered lists
- Links: Use `[text](url)` format
- Mermaid diagrams: Supported for architecture diagrams (see user rules for Mermaid guidelines)

## Editorial positioning

This site is not limited to HOW-TO articles. It publishes practical notes from software engineering, infrastructure work, AI tooling, and everyday systems the author has actually used.

Choose titles that match the content type:

- Use `How to ...` only for step-by-step guides.
- Use `Notes on ...`, `A Field Report on ...`, or `What I Learned from ...` for experience reports.
- Use `A Review of ...` for product or purchase reviews.
- Use direct technical titles for internals, architecture, or debugging notes.

Every post should have a concrete source of value: hands-on experience, reproducible steps, a clear technical model, a useful warning, or a defensible opinion.

## Categories

Use one primary category unless a post genuinely spans multiple areas:

- `Engineering` - programming, debugging, architecture, developer workflow, and general engineering models.
- `Databases` - TiDB, OceanBase, CockroachDB, MySQL, PostgreSQL, benchmarks, and distributed database notes.
- `Infrastructure` - Linux, networking, VPN, proxy, CI/CD, servers, security, and deployment.
- `AI Tools` - AI workflows, LLM tooling, agents, MCP, automation, and AI-assisted publishing.
- `Field Notes` - travel, business trip notes, and practical personal observations from real-world situations.
- `Reviews` - product notes, gear, bicycles, coffee devices, knives, fishing gear, and other hands-on reviews.

Keep tags narrower than categories. Tags should describe specific tools, products, technologies, places, or concepts.

## Commit rules

- Target branch: default branch only
- Prefer one commit per post for ordinary publishing changes
- Commit message format:
  "Publish: [post title]"
- Include all related files (post markdown + images) in a single commit
- Site-wide taxonomy, formatting, or editorial maintenance changes may update multiple posts in one clearly named commit

## Prohibited actions

- Do NOT modify themes, workflows, configs, or dependencies
- Do NOT delete existing posts
- Do NOT touch build output repositories

## Validation

Before committing content changes, run:

```bash
make check
```

This validates required front matter, slug/bundle consistency, relative image references, unused images, and image size limits. JPEG EXIF metadata is reported as a warning.
