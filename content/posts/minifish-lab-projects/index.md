---
title: "Minifish Lab Projects"
slug: "minifish-lab-projects"
date: "2026-05-24T08:00:00+08:00"
draft: false
summary: "A living map of the small systems, tools, experiments, and prototypes I keep under Minifish Lab."
description: "A living index of Minifish Lab projects, with short notes on what each project does, its current status, and the project notes in this series."
categories: ["Engineering"]
tags: ["minifish-lab", "projects", "personal-tools", "ai-tools", "databases"]
---

This is a living index of the projects I keep under Minifish Lab. Some of them are public. Some are private because they contain personal operations, deployment assumptions, trading workflow details, or code that is useful to me but not ready to be maintained for other people.

The goal of this series is not to pretend every small repository should become a product. The goal is to leave a useful engineering record: why each project exists, what design choices mattered, what I learned from it, and where the boundary is between a good private tool and a project worth publishing.

I will keep this page updated as projects change.

## Project map

| Project | Area | Source | Status | Project note |
|---|---|---|---|---|
| `PocketBabel` | AI / Browser app | Public | Active | [PocketBabel: Browser Translation Without a Backend](/posts/pocketbabel-browser-translation/) |
| `tailgate` | AI infrastructure | Private | Active | [Tailgate: A Private AI Gateway for Local and Remote Models](/posts/tailgate-private-ai-gateway/) |
| `qwen-local` | Local AI | Private | Active | [qwen-local: Running an OpenAI-Compatible Model Service on Apple Silicon](/posts/qwen-local-on-apple-silicon/) |
| `tapsurge` | Offline frontend tool | Private | Active | [TapSurge: An iPad Tap-Speed Tool Built for Competition Use](/posts/tapsurge-ipad-tap-test/) |
| `ob-sizer` | Database tooling | Private | Active | [OB Sizer: Turning Migration Sizing into a Browser Tool](/posts/ob-sizer-capacity-estimator/) |
| `agentd` | Agent runtime | Private | Experimental | Scheduled: 2026-05-26 |
| `tegdb` | Database | Public | Experimental | Scheduled: 2026-05-27 |
| `ob-skills` | AI workflow / Database | Public | Active | Scheduled: 2026-05-28 |
| `quacklake` | Analytics | Private | Prototype | Scheduled: 2026-05-29 |
| `scale-kv` | Storage systems | Private | Experimental | Scheduled: 2026-05-30 |
| `cta-guard` | Trading systems | Private | Sensitive | Scheduled: 2026-05-31 |
| `tegdb-server` | Database server | Public | Experimental | Scheduled: 2026-06-01 |
| `bedrock-lab` | Game modding | Private | Small tool | Scheduled: 2026-06-02 |
| `aeroplay` | Offline games | Public | Template-ready | Scheduled: 2026-06-03 |
| `map-ask` | Maps / AI | Private | Prototype | Scheduled: 2026-06-04 |
| `good-fishing-day` | Personal dashboard | Private | Personal utility | Scheduled: 2026-06-05 |

## Why write about private projects?

Open source is not the only useful form of sharing. A private project can still contain lessons worth publishing:

- how the problem was framed
- which constraints shaped the architecture
- what was deliberately left out
- where a prototype became too complex
- what I would do differently next time

For private repositories, these notes avoid secrets, private network details, exact production configuration, personal data, and sensitive business or trading parameters. The public artifact is the engineering story, not a dump of implementation details.

## How I classify these projects

Some projects are small tools that should stay small. `tapsurge`, `good-fishing-day`, and `bedrock-lab` are in that category. Their value comes from being built for one specific situation.

Some are experiments in system shape. `agentd`, `scale-kv`, `quacklake`, `tegdb`, and `tegdb-server` are more about understanding boundaries than shipping a polished product.

Some are workbench infrastructure. `qwen-local`, `tailgate`, `PocketBabel`, and `ob-skills` exist because I want AI tools to fit into my own environment instead of depending entirely on remote services.

Some projects sit close to professional or sensitive domains. `ob-sizer` is safe to discuss at the methodology level. `cta-guard` needs more caution: the interesting public topic is risk control and operational design, not trading edge.

## Maintenance rule

When a project changes meaningfully, I will update this index first. If the change is only implementation detail, the individual post can stay as a snapshot. If the project changes direction, graduates into a product, or gets retired, the index should say so plainly.

That makes this page the map, and each project post a field note.
