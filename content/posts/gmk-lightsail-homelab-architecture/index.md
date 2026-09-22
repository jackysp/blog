---
title: "Inside My GMK and Lightsail Homelab"
date: "2026-09-19T18:00:00+08:00"
draft: false
summary: "How I connect a GMK home server and a small Lightsail instance to run personal agents, local inference, messaging, and a shared virtual world—with private networking, external monitoring, and tested recovery."
description: "An architecture tour of my GMK and AWS Lightsail homelab: Tailscale, agentd, Tailgate, local-ai, Matrix, World Loom, Sentinel, Beszel, and NAS backups."
categories: ["Infrastructure"]
tags: ["homelab", "tailscale", "lightsail", "self-hosting", "agentd", "local-ai", "disaster-recovery"]
slug: "gmk-lightsail-homelab-architecture"
images: ["homelab-architecture.png"]
---

The projects on this blog often look independent: an agent runtime, a cycling route planner, an AI gateway, a browser game. In daily use, several of them share the same small infrastructure.

At home, a **GMK M5 Ultra** runs the applications that need memory, persistent storage, or local compute. A small **AWS Lightsail instance in Singapore** supplies the public entry point and runs lightweight network services. **Tailscale** connects them. A NAS stores encrypted backups, and a Cloudflare Worker watches the system from outside both machines.

That division lets me keep the cloud instance small while giving my projects a place to run continuously. The interesting part is how the pieces fit together: where requests enter, where state lives, which services remain private, and what happens when one machine disappears.

This is a snapshot of the running system on **September 19, 2026**, checked against the live hosts and deployment configuration. Repository links appear throughout; repositories marked **private** require access. Repository visibility was updated on **September 22, 2026**, when Canopy, Tailgate, the X adapter, and World Loom server were opened to the public.

## The architecture

[![Architecture of the Minifish homelab. Lightsail handles public ingress, transport adapters, and model routing. Tailscale connects it to GMK applications and local inference. Private clients reach GMK directly. Cloudflare hosts the World Loom frontend and the independent Sentinel monitor; encrypted backups go to a NAS.](homelab-architecture.png)](homelab-architecture.png)

[Open full resolution](homelab-architecture.png) · [Download editable SVG diagrams](diagrams-source.zip)

The diagram groups related services; it is not a map of every listening port. The two most important boundaries are the public/private network boundary and the separation between application state and its recovery copies.

| Location | What lives there | Why it belongs there |
| --- | --- | --- |
| GMK M5 Ultra | agentd, Canopy/GraphHopper, local-ai, Matrix/RTC, World Loom, Beszel | Local compute, memory, and persistent application data |
| Lightsail, Singapore | Nginx ingress, Telegram/X adapters, Tailgate, SimpleX, network utilities, Durvo server | Public reachability and lightweight services that can stay up independently of GMK |
| Tailscale network | Host connectivity, private HTTPS endpoints, administration | One private network across devices and locations |
| Cloudflare | World Loom static frontend; Sentinel Worker, D1, and Access | Static delivery and an observation point outside the two hosts |
| NAS | Encrypted Restic snapshots | Recovery data on a separate storage system |

The GMK has a Ryzen 7 7730U, 64 GB of installed RAM—about 62 GiB visible to Linux—and roughly 954 GiB of usable NVMe capacity. It runs native Debian 13 with Docker Compose. At inspection, it had eleven running application containers. The Lightsail instance has only about 442 MiB of memory visible to Linux and runs its services under systemd.

The memory-heavy services run at home, while small edge services can remain available independently of home power and connectivity.

## Lightsail is the public edge

Public Matrix requests arrive at Lightsail. Nginx sends them across Tailscale to Tuwunel on GMK. MatrixRTC authentication and LiveKit signaling follow the same broad path.

There are two layers at the HTTPS entry point. The outer Nginx stream listener examines the TLS server name and selects a local backend. For Matrix, RTC, and Durvo, that backend is an HTTP server block that terminates TLS and proxies the request. SimpleX services have their own TLS endpoints. This uses Nginx's [`ssl_preread`](https://nginx.org/en/docs/stream/ngx_stream_ssl_preread_module.html) support: selecting a backend from the ClientHello does not itself terminate the TLS connection.

Media needs a separate path. My LiveKit deployment uses TCP 7881 and UDP 7882, which Lightsail forwards with nftables DNAT and masquerading to GMK over Tailscale. The HTTPS proxy handles signaling; the media forwarding rules handle the corresponding WebRTC traffic. LiveKit documents these as its [ICE/TCP and UDP mux ports](https://docs.livekit.io/transport/self-hosting/ports-firewall/).

| Traffic | Lightsail's role | GMK destination |
| --- | --- | --- |
| Matrix client/server API | HTTPS reverse proxy | Tuwunel |
| MatrixRTC authorization | HTTPS reverse proxy | MatrixRTC Auth |
| LiveKit signaling | HTTPS/WebSocket reverse proxy | LiveKit API |
| LiveKit media | TCP/UDP forwarding | LiveKit media ports |

This distinction matters during debugging. An HTTP health check can pass while media forwarding is broken. The migration checks exercised the HTTP endpoints, TCP connectivity, and a UDP packet traversing the forwarding path; those checks alone do not prove that a complete two-party call works.

The upstream projects are [Tuwunel](https://github.com/matrix-construct/tuwunel), [LiveKit](https://github.com/livekit/livekit), and [MatrixRTC Authorization Service](https://github.com/element-hq/lk-jwt-service). My deployment configuration and recovery tooling live in [`infra`](https://github.com/minifish-org/infra) **(private)**.

## A personal agent request crosses the boundary more than once

The agent stack shows how the two machines share a workload.

[![Personal agent request flow. Telegram and X adapters on Lightsail submit turns to agentd on GMK. agentd calls Tailgate on Lightsail, which selects local-ai on GMK or a hosted provider. agentd can call Canopy and GraphHopper for route planning. Results are committed with an optional delivery outbox, which the adapters claim and acknowledge.](agent-request-flow.png)](agent-request-flow.png)

[Open the request-flow diagram at full resolution](agent-request-flow.png). A typical request follows this path:

1. The **Telegram adapter** receives a webhook, or the **X adapter** polls an eligible mention.
2. The adapter submits a turn to **agentd on GMK** through the private HTTPS endpoint.
3. agentd calls **Tailgate on Lightsail** using the configured model route.
4. Tailgate forwards the request to **local-ai on GMK** or a configured hosted provider.
5. agentd runs any permitted tools and persists the result. When delivery was requested, finalization also makes that result available through its delivery outbox.
6. The adapter claims the delivery, sends it through the platform API, and acknowledges it.

The adapters own platform-specific behavior. agentd owns execution and durable run state. The adapters do not reach into its database to find replies. This keeps Telegram webhook policy, X polling, media handling, and delivery retries out of the core runtime.

The outbox makes the handoff inspectable, but an external send and a local acknowledgment are still separate operations. It should not be read as a blanket exactly-once guarantee for a third-party API.

The public repositories are [`agentd`](https://github.com/minifish-org/agentd), [`agentd-telegram-adapter`](https://github.com/minifish-org/agentd-telegram-adapter), and [`agentd-x-adapter`](https://github.com/minifish-org/agentd-x-adapter). I discuss the runtime boundary in more detail in [agentd: A Transport-Neutral Runtime for Personal Agents](/posts/agentd-transport-neutral-runtime/).

### Why the model gateway stays on Lightsail

[`Tailgate`](https://github.com/minifish-org/tailgate) provides one OpenAI-compatible API with centralized provider credentials and explicit model routing. The running gateway is bound to the Lightsail Tailscale address; it is also available through Tailscale Serve. Living on a public VM does not make this API a public endpoint.

The configured upstreams currently include the GMK local-ai service, DeepSeek, and OpenRouter. A route such as `local/chat` identifies the local capability; other routes can select hosted models according to their configuration. Fallback behavior belongs to that policy—it should not silently turn every local request into a remote one.

This does create an extra trip: agentd on GMK calls Lightsail, which may call GMK again for local inference. I accept that for a shared policy point used by multiple clients. It also creates a real dependency: if Lightsail is down, agentd's configured model gateway is unavailable even when GMK is healthy. The direct local-ai endpoint is a separate access path, not an automatic agentd failover mechanism.

The earlier [Tailgate article](/posts/tailgate-private-ai-gateway/) describes the gateway design. Its original local backend was `qwen-local` on an Apple Silicon Mac. The live Lightsail configuration now points to **local-ai on GMK**.

### Local inference is a service, with a finite budget

[`local-ai`](https://github.com/minifish-org/local-ai) **(private)** exposes chat, embeddings, speech synthesis, transcription, and translation behind a compatible API. Its current deployment has an API container, a runtime container, and a separate resident chat server. The API and native chat webpage share that chat server.

The current chat setup runs on the CPU with six threads, one inference slot, and a 48 GiB container memory limit. Embeddings use the AMD Vulkan backend; the other capabilities retain their own backends. This is a mixed workload on one small machine, so the useful questions are concrete: what is resident, what is queued, and which requests contend for the same resources?

In particular, the direct chat webpage reaches the chat service without going through the API's cross-capability queue. It still uses the chat server's single slot, but that does not serialize every other workload on the host. Container memory limits are ceilings, not reservations; setting several limits does not create additional physical RAM.

### Canopy gives the agent a route engine

[`Canopy`](https://github.com/minifish-org/canopy) is an MCP service for Singapore cycling and walking routes. It uses a local GraphHopper instance for routing, with a model that prefers PCN-like and low-traffic paths. OneMap supplies geocoding and points of interest.

Canopy and GraphHopper run alongside agentd on GMK without host-published ports. The agent can ask a specialized tool to plan and audit a route, then explain the returned geometry, distance, and GPX output. The language model does not have to invent the route.

The deployment also distinguishes durable state from reproducible data: the GraphHopper graph cache is rebuildable and is excluded from the daily application-data backups. More on the tool itself: [Canopy: Local MCP Routing for Singapore PCN Loops](/posts/canopy-singapore-pcn-routing/). Its routing engine is [GraphHopper](https://github.com/graphhopper/graphhopper).

## A public frontend can have a private backend

World Loom is a small shared virtual world with a browser client and an authoritative Rust server. Its static client is served from Cloudflare Pages at [wl.minifish.org](https://wl.minifish.org/). The live world runs on GMK.

The browser downloads the client from Pages, then connects directly to the GMK's private HTTPS/WebSocket bridge through Tailscale. Cloudflare Pages does not proxy the gameplay connection. Opening the public webpage therefore does not grant access to the world; the client device still needs the private network connection.

The server owns world updates and persistence, including SQLite and Anvil region files. Its MCP interface lets a client inspect or edit the live world through the server's update loop. That endpoint is exposed through Tailscale Serve and also requires a bearer token. The browser bridge has an explicit origin allowlist.

[Tailscale Serve](https://tailscale.com/docs/features/tailscale-serve) supplies the private HTTPS entry points. The World Loom endpoints use Serve without Funnel; the same host also exposes private agentd, local-ai, and Beszel endpoints. Keeping an application behind the tailnet complements its own authentication and authorization.

Both [`world-loom-client`](https://github.com/minifish-org/world-loom-client) and [`world-loom-server`](https://github.com/minifish-org/world-loom-server) are public. The server includes a standalone MCP build/restart/undo demo and documents its experimental security boundaries, including known upstream dependency advisories. The integration workspace [`world-loom-stack`](https://github.com/minifish-org/world-loom-stack) remains **private**.

## Other services that belong at the edge

Lightsail also runs a few services with useful independent lifetimes:

- **SimpleX SMP and XFTP** provide messaging relay and file-transfer services. Both come from [simplexmq](https://github.com/simplex-chat/simplexmq).
- **Durvo** runs its single-node control server behind Nginx. [`Durvo`](https://github.com/minifish-org/durvo) **(private)** is my experimental SQLite recovery project, with immutable recovery objects in managed S3 and restoration into isolated staging targets.

Durvo is still a self-use experiment with unresolved capture-maturity limitations. The homelab recovery procedure described below relies on consistent snapshots and Restic; Durvo is not the protection mechanism for those application databases.

## Observe the machine from inside, and availability from outside

I use two monitoring layers because they answer different questions.

**[Beszel](https://github.com/henrygd/beszel)** runs on GMK: a containerized Hub and a native Agent. It shows CPU, memory, storage I/O, container activity, temperatures, and NVMe SMART information. The dashboard is available only through Tailscale. This is the view I use to understand whether inference is competing with other work or whether the host is running out of resources.

**[`Sentinel`](https://github.com/minifish-org/sentinel) (private)** has a different position. Short-lived probes on GMK and Lightsail periodically send signed reports to a Cloudflare Worker. The Worker also checks public Matrix, RTC, and Durvo endpoints, stores compact history in D1, and serves a status page protected by Cloudflare Access.

Lightsail can observe GMK's reachability and Beszel's HTTPS endpoint from another host. If GMK loses power, its local dashboard disappears, but the Worker and Lightsail remain separate observation points. When reports become stale, the monitor shows an explicit unknown state.

Sentinel's status page brings these observations together with incident history.

The useful distinction is between a process running, an application responding, and a scheduled job completing successfully. A running container does not prove that yesterday's backup succeeded.

## Recovery is part of the architecture

The backup job runs **each night**. It stops the main database writers—Tuwunel, World Loom, and agentd—creates consistent archives, verifies checksums, and starts those applications again before uploading to the NAS.

This introduces a deliberate service interruption during snapshot creation. For this personal workload, a straightforward consistency boundary is worth that interruption.

[Restic](https://github.com/restic/restic) stores encrypted snapshots on the NAS over SFTP. Retention combines daily, weekly, and monthly recovery points with short-lived local staging copies. Additional hooks capture Beszel's consistent database backup and local-ai's configuration and model manifest. Model weights and rebuildable caches are excluded from the routine backup; recovering them can require downloading or rebuilding them.

Regular repository checks and isolated restore drills exercise the recovery path. The automated restore drill covers the original application set. Beszel has integrity checks on each backup and a separately documented manual restore drill; adding a service to the backup archive does not automatically add it to every recovery test.

There is also an encrypted recovery bundle containing the captured configuration, operational tooling, consistent database archives, and application images from the core migration. That bundle has its own date and scope. It needs refreshing as services and deployment details change.

The NAS is a separate storage target, but that alone says nothing about geographic separation or every shared failure mode. Daily snapshots also leave changes since the last successful snapshot exposed to loss. Those are properties of the design, not things a successful checksum can fix.

### A migration made the recovery path real

On September 12, I moved the core services from a Mac/Colima deployment to native Debian on the GMK. Before switching traffic, I rehearsed restoration on isolated Docker networks and checked the restored applications.

At cutover, the source writers and timers were stopped, final data was captured, and the Lightsail upstreams and private client endpoints were changed. On the new host, the first NAS backup, repository check, isolated restore, and a production reboot were verified. The old Colima instance was then shut down with its frozen state retained.

The subtle part is rollback. Once the new host accepts writes, pointing traffic back at the frozen source can discard those writes. A retained machine is useful recovery material; it is not automatically a safe failback target.

## What this arrangement gives me

The GMK gives the projects room to work. Lightsail gives them a stable public edge and a shared model gateway. Tailscale lets private services remain reachable from my devices without turning each one into a public web application. Cloudflare supplies static delivery and an independent monitoring location, while the NAS and restore procedures make host replacement practical.

There are still clear failure domains. Losing GMK stops its agents, local inference, Matrix backend, and shared world. Losing Lightsail breaks the public entry path and configured model gateway. Neither machine automatically takes over the other's work.

For my current workload, the value is that I can follow a request across the system, find the state it changes, and explain how that state can be recovered. Each new project has to fit into that same model: an entry point, an execution boundary, a place for durable data, a health signal, and a recovery path.
