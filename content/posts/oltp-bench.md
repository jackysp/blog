---
title: "How to View CMU DB Group's OLTP-Bench"
slug: "how-to-view-cmu-db-groups-oltp-bench"
tags: ['database', 'benchmark']
date: 2018-02-23
---

## Introduction to OLTP-Bench

OLTP-Bench is an open-source benchmarking tool platform for OLTP scenarios from CMU's DB Group. It was designed to provide a simple, easy-to-use, and extensible testing platform.

It connects to databases via the JDBC interface, supporting the following test suites:

* TPC-C
* Wikipedia
* Synthetic Resource Stresser
* Twitter
* Epinions.com
* TATP
* AuctionMark
* SEATS
* YCSB
* JPAB (Hibernate)
* CH-benCHmark
* Voter (Japanese "American Idol")
* SIBench (Snapshot Isolation)
* SmallBank
* LinkBench

Detailed project information can be found [here](http://db.cs.cmu.edu/projects/oltp-bench/), and the GitHub page is [here](https://github.com/oltpbenchmark/oltpbench).

The project introduction page includes three papers published by the authors, with the one from 2013 being the most important, also linked on the GitHub page.

Based on the GitHub page, the project does not seem to have a high level of attention and has not been very active recently. Most issues and pull requests come from within CMU.

## OLTP-Bench: An Extensible Testbed for Benchmarking Relational Databases

The paper "OLTP-Bench: An Extensible Testbed for Benchmarking Relational Databases" can be regarded as the most detailed introduction to this project.

In the first and second chapters, the authors introduce the motivation for creating this framework, which is to integrate multiple test sets and provide features that simple benchmarking tools do not have, while offering excellent extensibility to attract developers to support more databases.

From the activity on GitHub, it is evident that this extensibility is more about adding database support rather than test sets. However, the number of supported test suites is already quite extensive.

Chapter three introduces the architectural design, with a focus on test suite management, load generators, SQL syntax conversion, multi-client scenarios (similar to multiple sysbench instances stressing a single MySQL), and result collection.

Chapter four discusses the supported test suites. I'm only familiar with TPCC and YCSB. The authors classify them from three perspectives:

1. Transaction-focused, such as TPCC and SmallBank
1. Internet applications, like LinkBench and Wikipedia
1. Specialized tests, such as YCSB and SIBench

Further details can be seen in the table:
[table]

Chapter five describes the demo deployment environment, with subsequent sections introducing the demo's features.

Chapter six uses the demo from the previous chapter to introduce features, analyzed as follows:

1. Rate control. It seems odd for a benchmarking tool to perform rate control, as the conventional understanding is to push performance as high as possible to gauge system limits. The paper provides an example using the Wikipedia test suite, increasing by 25 TPS every 10 seconds to observe database latency changes.

1. Tagging different transactions in the same test suite for separate statistics – using TPCC as an example to statistically categorize transactions from different stages.

1. Modifying load content, like switching from read-only to write-only loads.

1. Changing the method for load randomness.

1. Monitoring server status alongside database monitoring by deploying an OLTP-Bench monitor on the server.

1. Running multiple test suites simultaneously, such as running TPCC and YCSB concurrently.

1. Multi-client usage, mentioned in chapter three.

1. Repeatability. To prove OLTP-Bench results are genuine and reliable, the authors tested PG's SSI performance using SIBench from the tool on similarly configured machines, achieving results consistent with those in PG's SSI paper.

In summary, rate control and transaction tagging stand out as novel features, while the rest are not particularly special.

Chapter seven is arguably the most valuable part of the article, discussing cloud environments where users might only have database access and not server control. Users may struggle to assess the cost-effectiveness of different cloud database services or configurations due to charges encompassing CPU, storage, network, and asynchronous sync in some architectures. Thus, using benchmarking tools to derive performance and subsequently calculate cost-effectiveness is particularly worthwhile. This chapter compares varying perspectives: different service providers, configurations, comparing databases on the same configuration, and presents the cost-effectiveness outcomes.

In chapter eight, the authors compare OLTP-Bench with other similar tools, providing a favorable self-assessment.

Chapter nine outlines the authors’ future plans, including support for pure NoSQL, additional databases' proprietary SQL syntax, generating real-world load distributions from production data, and support for stored procedures.

In conclusion, as the authors mentioned, this is an integrative framework where ease of use and extensibility are key.

## Usage Summary

OLTP-Bench is relatively simple to install and use, especially the deployment. Its cross-platform nature provides a better user experience compared to traditional tpcc and sysbench. Usage is relatively straightforward due to the plethora of test configuration templates provided, allowing easy initiation of tests with simple configuration file modifications. The test results are stable, although certain features mentioned in papers, like server status monitoring, still require exploration.

I tested all 15 test suites on MySQL 5.7 and TiDB, obtaining the following results:
[table]

Its usability is quite evident. As for the ease of secondary development, it should be relatively simple, considering the entire OLTP-Bench project is not particularly large, with around 40,000 lines of code.

## Other

* tpch: While the framework's code appears to support tpch, it proved unusable during practical tests, likely due to incomplete implementation and thus excluded from the README.
* Referring to future work mentioned in chapter nine of the paper, especially "generating load to match production data distribution," this remains unimplemented, as seen in the codebase.
