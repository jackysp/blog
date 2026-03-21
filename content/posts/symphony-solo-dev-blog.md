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
  - openai
  - symphony
  - codex
categories:
  - engineering
summary: "Symphony, Linear, and Codex on two repos—with a deliberately harsh read on what comes next: customer-raised issues in, merged code out, and a shrinking middle of traditional PM and engineering headcount."
description: "Hands-on Symphony setup plus an unapologetic thesis: orchestration collapses the PM–engineer relay; B2B should route first-hand demand straight into automated build, test, and ship. Checklists and links included."
keywords:
  - OpenAI Symphony
  - openai/symphony
  - Linear
  - Codex
  - agent orchestration
  - WORKFLOW.md
  - solo developer
  - GitHub automation
  - B2B software delivery
  - product engineering workflow
---

I recently spent a session getting [OpenAI Symphony](https://github.com/openai/symphony) working on two personal repositories in a solo-developer setup. The goal was simple: use [Linear](https://linear.app/) as the task queue, let Symphony pick up issues automatically, and have Codex make code changes with as little manual coordination as possible.

This post is intentionally sanitized. I am not including tokens, local machine details, private paths, secrets, or any internal repository configuration that should not be published.

## Official Symphony resources

If you are trying to reproduce or extend this setup, start from the upstream project rather than this blog post alone:

- **Repository:** [github.com/openai/symphony](https://github.com/openai/symphony) — source, issues, and release notes.
- **Specification:** [`SPEC.md`](https://github.com/openai/symphony/blob/main/SPEC.md) — describes the intended behavior and interfaces.
- **Reference implementation:** [`elixir/`](https://github.com/openai/symphony/tree/main/elixir) — Elixir-based reference; follow the README there for build and run details.

Symphony is positioned as experimental or preview-quality software; run it only in environments and repositories you trust, and read the repo README for current limitations and safety expectations.

## Hands-on: from clone to first run

Everything below follows the [Elixir reference README](https://github.com/openai/symphony/blob/main/elixir/README.md). If a step fails, fix that step before tweaking your narrative expectations—the runtime is strict about valid `WORKFLOW.md` YAML at startup.

### 0. Prerequisites

- **Linear:** a workspace where you can create a **project** and issues inside that project.
- **Linear API key:** Settings → Security & access → Personal API keys. Export it in your shell (do not commit it):

  ```bash
  export LINEAR_API_KEY="your_linear_personal_api_key"
  ```

- **Codex CLI** with `codex app-server` available (Symphony launches Codex in [App Server mode](https://developers.openai.com/codex/app-server/)). Ensure `codex` is on `PATH` when the `codex.command` in `WORKFLOW.md` runs.
- **Runtime for the reference implementation:** the upstream docs recommend [mise](https://mise.jdx.dev/) for Erlang/Elixir versions; use `mise install` in `symphony/elixir` as documented.

### 1. Linear setup: workspace, team, project, workflow, and API key

Symphony only sees what Linear exposes through the API. If the board is wrong, every later step looks like a Symphony bug. Configure Linear **before** you wire `project_slug` into `WORKFLOW.md`.

#### 1.1 Workspace and team

- Use a Linear **workspace** you control (personal or org). You need permission to create **projects** and **issues** on a **team**.
- Pick the **team** that will own the automated work. Issues are always tied to a team; your project will live under that team’s context. For a solo setup, one dedicated team per “product line” or per repo is enough.

#### 1.2 Create a project (this is the Symphony queue boundary)

1. In Linear, open **Projects** (or the team’s project list) and **create a new project** for the repository you are automating (for example one GitHub repo ↔ one Linear project).
2. Give it a clear name so you do not file issues into the wrong queue later.
3. Open the **project** itself—not only the team backlog. Symphony’s `tracker.project_slug` refers to **this** project.

#### 1.3 Read the `project_slug` correctly

1. With the project open, copy the **page URL** from the browser address bar (or use “Copy link” if Linear offers it for the project).
2. The **slug** is the identifier in that URL that points at this project. Paste it into `WORKFLOW.md` as `project_slug` **exactly**—same spelling, same segment the URL uses.
3. If you rename the project or move it, re-check the URL and update `WORKFLOW.md`; a stale slug is an instant “nothing happens” failure.

#### 1.4 Align workflow **states** with `WORKFLOW.md`

Your simplified `WORKFLOW.md` lists `active_states` and `terminal_states` (for example `Todo`, `In Progress`, `Rework`, `Merging`, and terminals like `Done`, `Canceled`, `Cancelled`, `Duplicate`).

1. In Linear, open **Team settings** → **Workflow** (wording may vary slightly by plan and UI version).
2. Ensure the **team** that owns this project actually has **status** names that match what you put in YAML—**including spelling** (`Canceled` vs `Cancelled` are different strings).
3. If a state is missing, **add** it to the team workflow. If Linear ships a default you do not use (for example an extra backlog column), you can leave it unused; what matters is that every state your agent and YAML mention **exists** on the board.
4. Decide how issues **enter** the pipeline: many setups use `Todo` or `In Progress` as the first “Symphony should care” state. Put that state in `active_states` so polling can pick the issue up.

#### 1.5 Personal API key (Symphony uses `LINEAR_API_KEY`)

1. Open your **user Settings** → **Security & access** (or **API** / **Personal API keys**, depending on Linear’s UI).
2. Create a **new personal API key**, give it a label you will recognize (for example `symphony-local`).
3. Copy the key once, set `export LINEAR_API_KEY="..."` on the machine that runs Symphony, and **never** commit it to git or paste it into `WORKFLOW.md` unless you intentionally use env indirection like `tracker.api_key: $LINEAR_API_KEY` (still keep secrets out of the repo).

#### 1.6 Creating issues the way Symphony expects

1. **Create the issue inside the project:** from the **project** view, use **New issue** (or equivalent) so the issue is **associated with that project**. Creating an issue only on the team backlog without attaching the project is the classic “Symphony is idle” mistake.
2. Set **title** and **description** to something actionable; the Markdown body of `WORKFLOW.md` passes `issue.title` and `issue.description` into Codex.
3. Move the issue to a state listed under `active_states` (for example `Todo` or `In Progress`) so it is not sitting in a column Symphony does not poll.

#### 1.7 Optional but useful

- **Templates:** a small issue template (context, acceptance criteria, “how to validate”) makes agent runs less ambiguous.
- **Labels:** optional; Symphony does not require them unless you add logic elsewhere.
- **Permissions:** if the API key belongs to a restricted user, confirm that user can read and update issues in the target project.

After this, you can copy `project_slug` into `WORKFLOW.md` with confidence. If anything in this section is skipped, revisit **1.3** (slug) and **1.6** (issue in project) first when debugging.

### 2. Build the Symphony binary (reference implementation)

```bash
git clone https://github.com/openai/symphony
cd symphony/elixir
mise trust
mise install
mise exec -- mix setup
mise exec -- mix build
```

After this, the launcher is `./bin/symphony` inside `symphony/elixir` (see the same README). You can start it with an **absolute path** to any `WORKFLOW.md` you maintain:

```bash
mise exec -- ./bin/symphony /absolute/path/to/your/repo/WORKFLOW.md
```

If you omit the path, it defaults to `./WORKFLOW.md` in the current directory—useful when you are iterating inside a single checkout.

Optional flags from upstream:

- `--logs-root` — log directory (default: `./log` relative to how you invoke the binary).
- `--port` — also starts the optional Phoenix observability UI (dashboard/API as described in the Elixir README).

### 3. Add `WORKFLOW.md` to the repository you want automated

1. Copy the template from the Symphony repo: [`elixir/WORKFLOW.md`](https://github.com/openai/symphony/blob/main/elixir/WORKFLOW.md) → your target repo (often repo root).
2. **Edit the YAML front matter** for your world:
   - **`tracker.project_slug`:** in Linear, open your project, copy its URL from the browser, and take the **slug** segment (the README describes this explicitly).
   - **`workspace.root`:** a directory on disk where Symphony may create **one workspace per issue** (large disk is fine; this is not your git clone root—it is a parent for per-issue workspaces).
   - **`hooks.after_create`:** typically `git clone ... .` into that workspace so Codex works on a fresh copy of your code. Use the clone URL and branch you actually use (HTTPS or SSH is your choice; private repos need credentials on the machine running Symphony).
   - **`codex.command`:** must match how you invoke App Server locally (model flags, config, etc.). If this command is wrong, the agent never comes up cleanly.

3. Align **Linear workflow states** with what `WORKFLOW.md` expects. The stock template references states such as `Todo`, `In Progress`, `Rework`, `Human Review`, and `Merging`. If your team uses different names, either rename states in Linear (Team Settings → Workflow) or edit `active_states` / `terminal_states` and the Markdown “status map” in `WORKFLOW.md` so they match reality.

4. Optionally copy the **skills** from the Symphony repo (`commit`, `push`, `pull`, `land`, `linear`, etc.) into your repo if your workflow prompt expects them—the Elixir README calls this out.

Symphony **does not boot** if `WORKFLOW.md` is missing or the YAML front matter is invalid; fix the file and restart.

### 4. Run and sanity-check before opening a ticket

```bash
export LINEAR_API_KEY="..."   # if not already in your shell profile
cd /path/to/openai/symphony/elixir
mise exec -- ./bin/symphony /path/to/your/automated/repo/WORKFLOW.md
```

Then verify:

- The process stays running and polls on the interval you set (`polling.interval_ms` in the template).
- If you passed `--port`, you can hit the dashboard/API URLs documented in the Elixir README for live state.

### 5. First Linear issue (the mistake that looks like “Symphony is broken”)

Do this in order or you will get silent no-ops:

1. Create or pick a **Linear project** whose slug matches **`tracker.project_slug`** exactly.
2. Create the issue **inside that project**, not as a free-floating team issue.
3. Put the issue in an **active** state listed under `active_states` in `WORKFLOW.md` (for the default template, something like `Todo` or `In Progress`—not `Backlog` if your prompt tells the agent to ignore `Backlog`).

If Symphony polls successfully but your issue never enters the watched project, you will see healthy logs and zero useful work—this is the `project_slug` lesson from later in this post.

### 6. Two repos (repeat the pattern)

For each codebase, maintain **its own** `WORKFLOW.md`, **its own** Linear project (and slug), **its own** `workspace.root`, and run **its own** `./bin/symphony .../WORKFLOW.md` process. Trying to multiplex multiple repositories through one workflow file is how you get accidental coupling and confusing failures.

---

If you want the upstream one-liner to bootstrap with Codex inside your repo, the FAQ in the Elixir README suggests pointing Codex at [`elixir/README.md`](https://github.com/openai/symphony/blob/main/elixir/README.md) and asking it to wire files for your codebase—still verify `project_slug`, workspace paths, and git remotes yourself.

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

The [stock `elixir/WORKFLOW.md`](https://github.com/openai/symphony/blob/main/elixir/WORKFLOW.md) in the Symphony repository is intentionally large: long status maps, PR sweeps, workpad templates, and guardrails meant for serious team-style orchestration. For solo maintenance on a small repo, that is often more surface area than you want to own on day one.

What I actually wanted was a **small YAML front matter** plus a **short agent brief** that still respects Linear state and runs a tight validate loop.

The elements I kept in practice:

- one Linear project per repository
- one Symphony process per repository
- one workspace root per repository
- explicit active and terminal states (only the ones I really use)
- explicit install/setup commands in `after_create`
- explicit validation before completion (`npm` in my case)
- `codex app-server` with sandbox left at workspace write, approval policy set explicitly so the run does not stall on prompts

### A simplified `WORKFLOW.md` (sanitized)

Below is the **shape** of the workflow file I run. Values such as the Linear project slug, workspace directory, and git remote are **placeholders**—replace them with your own. Do not copy real identifiers from this post into production without checking them in Linear and Git.

```md
---
tracker:
  kind: linear
  project_slug: "your-linear-project-slug"
  active_states:
    - Todo
    - In Progress
    - Rework
    - Merging
  terminal_states:
    - Done
    - Canceled
    - Cancelled
    - Duplicate

polling:
  interval_ms: 5000

workspace:
  root: ~/symphony-workspaces/your-repo-short-name

hooks:
  after_create: |
    git clone --depth 1 https://github.com/your-org/your-repo.git .
    npm install

agent:
  max_concurrent_agents: 1
  max_turns: 20

codex:
  command: codex app-server
  approval_policy: never
  thread_sandbox: workspace-write
  turn_sandbox_policy:
    type: workspaceWrite
---

You are working on a Linear issue {{ issue.identifier }}.

Title: {{ issue.title }}
Body: {{ issue.description }}

Rules:

- Always start by understanding the current state of the issue.
- If state is Todo, move it to In Progress.
- If state is Rework, review existing changes and fix issues.
- If state is Merging, finalize merge (do not keep coding).

Execution:

1. Understand the task
2. Reproduce or reason about current behavior
3. Make minimal safe changes
4. Run:
   - npm run build OR npm test
5. If success:
   - commit changes
   - push branch or merge directly according to repository flow

Do not:

- Ask humans for help
- Modify files outside workspace
- Skip validation

Goal:

Deliver working code change with valid validation and keep the Linear issue state accurate.
```

### How to fill this in safely

- **`project_slug`:** in Linear, open the project and copy its URL; the slug is the path segment that identifies the project (see the Elixir README). It must match the project where you create issues.
- **`workspace.root`:** any empty-friendly parent directory on the machine that runs Symphony; Symphony creates a subdirectory per issue under this root.
- **`after_create`:** use your real `git clone` URL and package install command (`npm install`, `pnpm install`, `make`, and so on).
- **Linear states:** your team must actually define or use states compatible with `active_states` / `terminal_states`. If Linear uses different names, edit the lists to match.

This was a much better balance for me than copying the entire official workflow verbatim, while still staying inside Symphony’s YAML + Markdown contract.

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

## Future potential: kill the relay

Symphony is not competing with tab completion. It is a probe for a nastier question: **if work is just queue + policy + execution, why would you keep a permanent class of people whose main job is to sit between a customer sentence and a git merge?**

Here is the version I actually believe.

**B2B should look like a pipe, not a committee.** Whoever hears the customer—sales engineer, CS, onboarding, whoever—**opens the issue**. That issue is the contract. Behind it, **Symphony-grade orchestration** does the rest: clone, implement, test, merge, release. Not “faster Jira.” Not “AI assists your sprint.” **The default path is machine throughput; humans are for edge cases, politics, and blame.**

Does that erase humans? No—it erases **the middle**. The classic career ladder where “product” rewrites reality for “engineering” so engineering can rewrite it again for Git is not destiny. It is **coordination rent**. Orchestration is a wrecking ball aimed at that rent. If your value is mostly translating between tools and meetings, the stack is not coming to help you—it is coming to **delete the slot**.

You can list risks forever—compliance, security, hallucinations, bad merges—and you should. But risk is not a moral argument for headcount. It is an argument for **thinner, sharper ownership**: a tiny number of people who set policy and own catastrophes, plus a machine that does the boring middle at machine speed.

Yes, today’s tools are still a preview: flaky, embarrassing, unsafe if you are lazy about validation. **Irrelevant to the direction.** The direction is **first-hand demand in, shipped software out**, with as few interpreters as the market will tolerate. In ten years, “we need more PMs and more engineers because that is how software is made” will read like “we need more telephone switchboard operators because calls exist.”

My two-repo setup is a toy. The logic is not.

## Appendix: sanitized lessons learned

- Configure Linear (project, slug, workflow states, API key, issues inside the project) before blaming Symphony
- Start with one repo, not many
- Keep one workflow per repo
- Use one Linear project per repo
- Make state transitions explicit
- Do not rely too much on defaults
- Validate aggressively before allowing automated landing
- Expect the first “nothing happened” failure to be a scoping mistake
