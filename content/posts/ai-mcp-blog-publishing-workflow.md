---
title: "From AI Conversations to Published Blog: The MCP-Powered Publishing Revolution"
slug: "ai-mcp-blog-publishing-workflow"
date: "2026-01-19T10:00:00+08:00"
draft: false
tags: ['ai', 'mcp', 'github-actions', 'automation', 'blog-publishing', 'developer-productivity']
---

## The Problem: Lost Context, Lost Thoughts

We've all been there. You're deep in a technical discussion with an AI assistant—analyzing code, exploring architecture, or debugging a complex issue. The conversation is rich with insights, and you think: "This would make a great blog post."

But then reality hits: you need to switch to your blog repository, format the content, commit it, push it, and wait for the build. By the time you're back, the original context is gone, and the momentum is lost.

**What if you could publish directly from where you are?**

## Building on Existing Automation

In [my previous post about automatically publishing a blog using GitHub Actions](/posts/github-action), I set up a workflow where pushing to the blog repository triggers an automatic build and deployment to GitHub Pages. This solved the build and deployment automation, but there was still one manual step remaining: creating the post file itself.

The workflow I described there handles:
1. Checking out the blog repository
2. Building the Hugo site with `make`
3. Deploying to `jackysp.github.io`

But you still needed to be in the blog repository to create the post. That's where MCP changes everything.

## Enter MCP: The Missing Link

The [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) is revolutionizing how AI agents interact with external systems. Instead of treating AI as a passive tool, MCP enables agents to act as autonomous agents with direct access to your tools and workflows.

In my setup, I've connected MCP-enabled agents (like Cursor) directly to my blog repository via GitHub MCP. This means:

- **No context switching**: Stay in your current working directory, whether it's a random project folder or a deep codebase exploration
- **Preserve conversation flow**: The AI maintains the full context of your discussion
- **Direct publishing**: Create and publish posts without leaving your IDE

## The Architecture: Seamless Integration

Here's how the complete workflow operates:

```
┌─────────────────────────────────────────────────────────┐
│  AI Agent (Cursor/Claude) with MCP enabled              │
│  - Context: Any code repository or discussion            │
│  - Tool: GitHub MCP Server                               │
└──────────────────┬──────────────────────────────────────┘
                   │
                   │ Creates post via GitHub MCP
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  Blog Repository (jackysp/blog)                         │
│  - content/posts/[new-post].md                          │
│  - Commit: "Publish: [title]"                           │
└──────────────────┬──────────────────────────────────────┘
                   │
                   │ Push to master branch
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  GitHub Actions (from previous post)                     │
│  - Build: Hugo static site generation                   │
│  - Deploy: Push to jackysp.github.io                    │
└──────────────────┬──────────────────────────────────────┘
                   │
                   │ Published
                   │
                   ▼
┌─────────────────────────────────────────────────────────┐
│  Live Site (jackysp.github.io)                          │
│  - Post is live and accessible                           │
└─────────────────────────────────────────────────────────┘
```

The GitHub Actions part remains exactly as described in the previous post—no changes needed there. The MCP layer adds the ability to trigger it from anywhere.

## The Workflow in Action

### 1. AI-Powered Content Creation

When you're discussing a technical topic with an AI agent, you can simply ask:

> "Turn this discussion into a blog post and publish it."

The AI agent, with access to GitHub via MCP, can:

- Extract key insights from your conversation
- Format content according to Hugo front matter requirements
- Create properly structured markdown files
- Handle images and assets
- Commit and push to the repository

### 2. Automated Build & Deploy

The moment a post is pushed to the `master` branch, the same GitHub Actions workflow from the previous post kicks in:

```yaml
on:
  push:
    branches: [ master ]
```

The workflow (as detailed in [the previous post](/posts/github-action)):
1. Checks out the blog repository with submodules
2. Builds the Hugo site using `make`
3. Deploys the built artifacts to `jackysp.github.io`

All without manual intervention.

### 3. Governance Through Contracts

To ensure quality and prevent accidents, I've implemented an **AI Publishing Contract** (`PUBLISHING.md`) that defines:

- **Allowed paths**: Only `content/**` and `static/**` can be modified
- **Post format**: Required front matter fields (title, date, tags, slug, summary)
- **Image handling**: Standardized location and reference format
- **Commit conventions**: Single commit per post with descriptive messages

This contract ensures that AI agents can publish content while respecting the repository structure and quality standards.

## Why This Matters: The Developer Experience Revolution

### Zero Context Switching

Traditional workflow:
1. Copy conversation → Switch to blog repo → Format → Commit → Push → Wait
2. **Context lost**, momentum broken

New workflow:
1. Ask AI to publish → Done
2. **Context preserved**, workflow continuous

### Capturing Technical Insights

The best technical insights often emerge during active problem-solving. With this workflow, you can:

- Document discoveries in real-time
- Turn debugging sessions into tutorials
- Transform architecture discussions into deep-dives
- Share codebase explorations as learning resources

### Scaling Knowledge Sharing

Previously, the friction of publishing meant many valuable insights were never written down. Now, the barrier to publishing is minimal, making it easier to:

- Share learnings with your team
- Build a personal knowledge base
- Contribute to the developer community
- Document your problem-solving journey

## Technical Implementation Details

### MCP Server Configuration

The GitHub MCP server provides the AI agent with:
- Repository read/write access
- File creation and modification
- Commit and push capabilities
- Branch management

### GitHub Actions Workflow

The CI/CD pipeline (as described in [the previous post](/posts/github-action)) handles:
- Go environment setup (for Hugo builds)
- Repository checkout with submodules
- Site generation via `make`
- Deployment to GitHub Pages repository

No changes needed to the existing workflow—it just gets triggered from a new entry point.

### Hugo Site Configuration

Posts follow Hugo's standard structure:
- **Location**: `content/posts/`
- **Format**: YAML front matter + Markdown content
- **Images**: Stored in `content/posts/images/`
- **Draft control**: `draft: true/false` for preview/publish

## The Future: AI-Augmented Documentation

This workflow represents a shift toward **AI-augmented documentation**. Instead of treating AI as a writing assistant, we're treating it as a publishing agent that can:

- Understand context from code discussions
- Extract technical insights automatically
- Format and structure content appropriately
- Publish without breaking workflow

As MCP and similar protocols mature, we'll see more sophisticated capabilities:
- Automatic code analysis and explanation
- Multi-post series generation from extended discussions
- Cross-referencing with existing content
- SEO and metadata optimization

## Getting Started

If you want to set up a similar workflow:

1. **Set up automated publishing** (see [my previous post](/posts/github-action))
2. **Enable MCP in your AI agent** (Cursor, Claude Desktop, etc.)
3. **Configure GitHub MCP server** with repository access
4. **Define publishing contracts** for governance
5. **Start publishing** from your conversations

The technical details are straightforward, but the impact on productivity and knowledge capture is profound.

## Conclusion

The intersection of AI agents, MCP protocols, and automated CI/CD creates a new paradigm for technical publishing. By building on the existing GitHub Actions automation and adding MCP as the entry point, we eliminate context switching and reduce friction.

This isn't just about automating blog posts—it's about **preserving the flow state of technical discovery** and making knowledge sharing as natural as having a conversation.

The future of technical documentation is here, and it's conversational.

---

*This post was created and published using the exact workflow described above—from a discussion about workflow automation to a live blog post, all without leaving the conversation context.*
