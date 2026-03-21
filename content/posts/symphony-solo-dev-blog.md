---
title: "Running OpenAI Symphony as a Solo Developer Across Two Repos"
date: 2026-03-20T21:00:00+08:00
draft: false
tags:
  - ai
  - agents
  - automation
  - linear
  - github
  - hugo
categories:
  - engineering
summary: "A practical write-up on using Symphony, Linear, and Codex to automate work on two personal repositories, including workflow design, early mistakes, and what felt surprisingly useful."
---

I recently spent a session getting OpenAI Symphony working on two personal repositories in a solo-developer setup. The goal was simple: use Linear as the task queue, let Symphony pick up issues automatically, and have Codex make code changes with as little manual coordination as possible.

This post is intentionally sanitized. I am not including tokens, local machine details, private paths, secrets, or any internal repository configuration that should not be published.

## Why I tried this

What interested me most about Symphony was not “AI that writes code” in isolation. I already have coding tools for that. The interesting part was orchestration:

- a task source
- a state machine
- an isolated workspace per task
- an agent runtime
- a repeatable loop from issue to code change

That is a different shape of workflow from normal editor-assisted coding.

## Why I used Linear instead of GitHub Issues

One thing became clear very quickly: Symphony is designed around Linear as the source of truth for work. It does not naturally start from GitHub Issues. Instead, the workflow looks more like this:

1. Create a Linear issue
2. Symphony polls the configured Linear project
3. Symphony creates a dedicated workspace for that issue
4. Codex works inside that workspace
5. The workflow advances by issue state

At first this felt a little strange, because I am used to GitHub Issues being the center of project work. But after testing it, I could see the logic. Linear is the task system. GitHub is the code system.

## The first practical lesson: project scoping matters

A surprisingly easy mistake was creating an issue in the wrong place.

I had a Linear workspace and a correctly configured project, but the first issue I created was not actually attached to the project that Symphony was watching. From the outside it looked like “nothing is happening,” but the real problem was much simpler: Symphony was correctly polling the configured project and my issue was outside that scope.

That was a good reminder that in this setup, `project_slug` is not a decorative field. It is the queue boundary.

## Making `WORKFLOW.md` actually usable

The official workflow file is much more than a small YAML config. It is really a mix of:

- tracker configuration
- workspace lifecycle
- agent execution settings
- sandbox policy
- operational instructions

My early version was too minimal. It could run, but it was not shaped enough for reliable solo use.

I ended up moving toward a more practical version with these elements:

- one Linear project per repository
- one Symphony process per repository
- one workspace root per repository
- explicit active and terminal states
- explicit install/setup commands in `after_create`
- explicit validation before completion

For my use case, this was a much better balance than trying to copy the entire official workflow verbatim.

## The first real run

Once the workflow was wired correctly, the first successful run was a great moment. The basic flow worked:

1. Create a Linear issue
2. Symphony picks it up
3. A workspace is created
4. The repository is cloned
5. Dependencies are installed
6. Codex makes a change
7. Validation runs
8. The issue moves forward in the workflow

That first time matters because it changes the whole thing from “interesting repo I am reading” into “real tool I can use.”

## A workflow surprise: no PR, direct merge

One unexpected result was that the run did not produce a pull request. Instead, it created a branch and then merged directly into `main`.

For a team workflow, that would be a problem. For my personal setup, I actually found it acceptable.

Because I am the only person using this flow right now, direct merge is not automatically bad. It is fast, and it fits a solo maintenance loop. The tradeoff is obvious: less review structure, more need for good validation and discipline.

If I later want a stricter process, the right fix is probably branch protection plus a stronger PR gate in the workflow.

## Why I accepted a “solo mode”

After thinking about it, I realized there are really two different modes here:

### Team mode

- branch protection
- pull requests
- human review gates
- merge discipline

### Solo mode

- fast issue pickup
- direct code change
- direct landing when validation passes

For now I am explicitly leaning toward solo mode. That is not because it is universally better. It is just a better fit for a single developer trying to reduce friction on personal repos.

## Scaling from one repo to two

After getting the first repository working, I wanted to know whether I could use Symphony across more than one repo.

The answer was yes, but not by forcing one workflow to manage everything. The cleaner model was:

- one Linear project per repository
- one `WORKFLOW` file per repository
- one Symphony process per repository
- one workspace root per repository

That means each repo gets its own queue, workspace, and execution loop. The result is much easier to reason about than trying to multiplex multiple repos through a single workflow.

Conceptually, the setup became:

```text
Repo A -> Linear Project A -> Symphony Process A
Repo B -> Linear Project B -> Symphony Process B
```

That separation made the system feel much more stable.

## Things that felt weird

A few things still feel unusual in this setup:

### 1. Linear is the real driver

If you are used to GitHub-centric project flow, it takes a minute to reset your intuition.

### 2. The workflow file is closer to an operating manual than a config file

It is not just about parameters. It strongly shapes agent behavior.

### 3. Small scope mistakes create “silent failures”

If the wrong project is watched, or the issue is created in the wrong place, everything can look healthy while nothing useful happens.

### 4. Defaults are often too implicit

Model choice, reasoning depth, safety behavior, and merge style all become much clearer once they are explicitly set instead of left to defaults.

## What I would improve next

There are a few upgrades that would make this setup stronger without making it too heavyweight:

- make validation stricter before landing changes
- make commit messages more informative
- optionally require PRs for selected repos
- capture a better audit trail of what the agent actually did
- design a lightweight rollback path for bad automated changes

That would preserve the speed of solo mode while reducing the risk of bad direct merges.

## Final take

My main takeaway is that Symphony becomes much more interesting once it is treated as a workflow runtime, not just a coding demo.

The useful mental model is not “an AI that edits files.” It is closer to this:

- work arrives through a queue
- each task gets an isolated environment
- the agent runs inside a bounded workflow
- the repo is just one part of the system

For a solo developer, that can actually be a very comfortable way to work, as long as the workflow is shaped carefully enough.

It is still early, still a little rough, and definitely not something I would blindly trust everywhere. But for small personal projects, it already feels surprisingly real.

## Appendix: sanitized lessons learned

- Start with one repo, not many
- Keep one workflow per repo
- Use one Linear project per repo
- Make state transitions explicit
- Do not rely too much on defaults
- Validate aggressively before allowing automated landing
- Expect the first “nothing happened” failure to be a scoping mistake
