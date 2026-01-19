# AI Publishing Contract for jackysp/blog

This document defines the ONLY allowed way for AI agents
to publish content into this repository.

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
  content/posts/

## Post format

- Hugo front matter format: YAML
- Required fields:
  - title (string)
  - date (RFC3339 format with timezone +08:00, e.g., "2026-01-17T10:00:00+08:00")
  - draft (boolean: true for drafts, false for published posts)
  - tags (array of strings)
  - slug (string, URL-friendly identifier)
  - summary (string, brief description for previews)

### Front matter example

```yaml
---
title: "Your Post Title"
date: "2026-01-17T10:00:00+08:00"
draft: false
tags: ["tag1", "tag2", "tag3"]
slug: "your-post-slug"
summary: "A brief summary of the post content."
---
```

### Slug format rules

- Use lowercase letters, numbers, and hyphens only
- No spaces or special characters
- Keep it concise and descriptive
- Example: "oceanbase-internals-transaction-replay" (not "OceanBase Internals: Transaction Replay")

### Summary guidelines

- Keep summary concise (1-2 sentences recommended)
- Should provide a clear overview of the post content
- Used in post listings and previews

## File naming

- **Required format**: `content/posts/slug.md`
- Use only the slug (lowercase letters, numbers, and hyphens) as the filename
- Do NOT include date prefix in filename (date is already in front matter)
- Example: `ai-mcp-blog-publishing-workflow.md` (not `2026-01-19-ai-mcp-blog-publishing-workflow.md`)

## Images

### Image storage location

- **All images MUST be placed in:** `content/posts/images/`
- Store images directly in this directory (no subdirectories required)

### Image reference format

- Reference images in markdown using: `/posts/images/filename.ext`
- Example: `![alt text](/posts/images/20241210_093935_image.jpg)`

### Image naming conventions

- Use descriptive filenames with timestamps or meaningful names
- Supported formats: `.png`, `.jpg`, `.jpeg`, `.JPG`, `.gif`, `.webp`
- Examples:
  - `20241210_093935_image.jpg` (timestamp-based)
  - `screenshot-diagram.png` (descriptive)

### Image usage in posts

```markdown
![Image description](/posts/images/filename.png)
```

### Image best practices

- Use descriptive alt text for accessibility
- Optimize images before uploading (reasonable file sizes)
- Maintain consistent naming patterns

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

## Commit rules

- Target branch: default branch only
- One commit per post
- Commit message format:
  "Publish: [post title]"
- Include all related files (post markdown + images) in a single commit

## Prohibited actions

- Do NOT modify themes, workflows, configs, or dependencies
- Do NOT delete existing posts
- Do NOT touch build output repositories
