---
title: "OB Sizer: Turning Migration Sizing into a Browser Tool"
slug: "ob-sizer-capacity-estimator"
date: "2026-05-24T08:25:00+08:00"
draft: false
summary: "OB Sizer is a frontend-only capacity estimator for OceanBase migration conversations."
description: "A project note on OB Sizer, a browser-based OceanBase migration capacity estimator for common source databases and workload assumptions."
categories: ["Databases"]
tags: ["oceanbase", "capacity-planning", "migration", "frontend-tool", "database"]
---

OB Sizer is an OceanBase migration capacity estimator. It helps solution architects turn rough source-system facts into an initial OceanBase cluster sizing conversation.

It is a pure frontend tool. All calculations run in the browser, and the estimate can be shared through encoded URLs.

## Why build it

Sizing discussions often begin with incomplete information:

- source database type
- data size
- growth expectations
- workload style
- read/write ratio
- availability requirement
- target deployment shape

The first estimate is rarely final. But without a structured model, the conversation quickly becomes a spreadsheet with hidden assumptions.

OB Sizer makes the assumptions visible.

## Supported shape

The tool covers common migration sources:

- MySQL
- Oracle
- PostgreSQL
- TiDB
- Aurora
- SQL Server

It models OceanBase replica choices such as `2F1A` and `3F`, real OB Cloud SKU shapes, and workload differences across OLTP, HTAP, and mixed patterns.

The important design choice is that it is not only a calculator. It includes methodology in the app, so users can see why a number appears.

## Product boundary

OB Sizer should not pretend to replace a real sizing engagement. The correct role is earlier:

- make first-pass estimates consistent
- expose assumptions
- help compare scenarios
- create a common language for follow-up questions

That boundary keeps the tool useful without making it misleading.

## Why browser-only

A browser-only tool is easy to share and easy to run in customer-facing discussions. It also avoids collecting workload information on a backend.

The tradeoff is that the model and SKU tables have to ship with the app. That is acceptable because the tool is a discussion aid, not a real-time pricing or provisioning system.

## What I learned

Capacity estimation tools are part engineering and part communication. A technically clever formula is not useful if the user cannot see its assumptions.

The best parts of OB Sizer are the ones that make uncertainty explicit:

- workload multipliers
- replica mode impact
- CPU and memory assumptions
- storage overhead
- write amplification
- safety margins

For database migration work, that transparency matters more than pretending the first number is exact.
