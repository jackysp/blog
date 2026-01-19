---
title: "How to Read TiDB Source Code (Part 2)"
slug: "how-to-read-tidb-source-code-part-2"
tags: ['tidb', 'database', 'source-code']
date: 2020-07-12T12:09:00+08:00
---

Continuing from [the previous article](/posts/tidb1), we learned how to set up the environment for reading code and where to start reading the code. In this part, we'll introduce methods for viewing code based on some common needs.

## How to Check the Support Level of a Syntax

There are usually two methods:

1. Check through the parser repo
1. Directly check within the TiDB repo

Both of these methods require the [environment setup from the previous article](/posts/tidb1#环境搭建). If you haven't tried that yet, give it a go.

### Preparation

1. Install GoYacc Support

    ![goyacc](/posts/images/20200712124300.webp)

    The GoYacc Support plugin is a creation by a colleague at our company, a third-party plugin officially accepted by JetBrains, a well-regarded product. It includes syntax highlighting and intelligence, which is great!

1. Download [parser repo](https://github.com/pingcap/parser)

    If you're checking syntax directly from the parser, you need to download it manually. If you're navigating from TiDB, IDEA will automatically download the code, so no extra steps are needed.

### Check via parser repo

Open the parser using IDEA, switch to the branch you need, and locate the parser.y file. However, it is more recommended to check from within TiDB.

### Check via TiDB repo

1. Open the TiDB project with IDEA and switch to the required branch

    ![co](/posts/images/20200712183012.webp)

1. Find the parser.y file; make sure to select the broadest search scope

    ![parser.y](/posts/images/20200712183658.webp)

    Alternatively, you can find it in the file list,

    ![parser.y2](/posts/images/20200712184101.webp)

    ![parser.y3](/posts/images/20200712184157.webp)

Let's take checking the `SHOW ENGINES` SQL statement as an example.

The entry point for the entire statement parsing is [Start](https://github.com/pingcap/parser/blob/f56688124d8bbba98ca103dbcc667d0e3b9bef30/parser.y#L1309-L1308). Below it is the StatementList, followed by Statement. Under the large list of Statements, you can find ShowStmt.

![parser.y4](/posts/images/20200712184841.webp)

However, ShowStmt is actually quite complex. Another way is to directly search for `ShowEngines` within parser.y, since naming follows Golang conventions, with camel case and capitalized letters for public exposure. Naturally, if familiar with the code, you'd know `ShowEngines` is under `ShowTargetFilterable`. Its first branch is `ShowEngines`.

![parser.y5](/posts/images/20200712185533.webp)

**What is the level of support for `SHOW ENGINES`?**

You can look at how `ast.ShowEngines` is processed. Here, you can't just jump to it; you need to copy and search.

![parser.y6](/posts/images/20200712190242.webp)

You only need to see how it's processed under TiDB, and you can skip test files.

![parser.y7](/posts/images/20200712190752.webp)

One is the actual implementation,

![parser.y7](/posts/images/20200712190839.webp)

The other is the build schema, which you can ignore for now,

![parser.y7](/posts/images/20200712190956.webp)

Entering `fetchShowEngines`, you can see the specific implementation is simple, running an internal SQL to read a system table.

![parser.y7](/posts/images/20200712191054.webp)

Checking `SHOW ENGINES` ends here. You can see that it's fully supported.

**Which statements only have syntax support?**

Taking the temporary table creation syntax as an example, find its position in the parser.y file.

![parser.y8](/posts/images/20200712191711.webp)

It's an option.

![parser.y9](/posts/images/20200712191843.webp)

You can see that if the temporary table option is specified, it simply returns true with an attached warning, stating that the table is still treated as a regular table. Previously, the parser had a lot of operations that only returned without doing anything, not even a warning, but these are now rare.

#### Advantages of Querying via TiDB repo

You can see that checking via the TiDB repo allows you to find the parser's detailed hash using IDEA. If you check directly via the parser, you need to first look up the parser’s hash in TiDB’s go.mod, then check out to the corresponding hash in the parser. If you need to check specific implementations, you have to go back to TiDB, making back-and-forth checks less convenient compared to looking within a single project. The only advantage is the ease of blaming commit history.

## Viewing and Modifying Default Configuration

The default configurations can be easily viewed in TiDB, specifically the variable [defaultConf](https://github.com/pingcap/tidb/blob/72f6a0405837b92e40de979a4f3134d9aa19a5b3/config/config.go#L547). The configurations listed here are the actual default settings.

![conf1](/posts/images/20200713172228.webp)

Taking the first Host configuration as an example, it has a mapping to toml and json files.

![conf2](/posts/images/20200713172535.webp)

This essentially shows how it's written in a toml file. The `DefHost` following it is the specific default value.

![conf3](/posts/images/20200713180137.webp)

Something important to note is that configurations have a hierarchical relationship. For example, the log-related configuration in the configuration file is:

![conf4](/posts/images/20200715164756.webp)

In the code, it is represented as:

![conf5](/posts/images/20200715164930.webp)

This denotes a configuration called "level" under the log configuration.

What if you want to add more levels? For instance, the most complex configuration for CopCache adds another layer under tikv-client called copr-cache.

![conf6](/posts/images/20200715165243.webp)

Since toml files do not support multi-level nesting, this leads to the most complex configuration writing in TiDB.

![conf6](/posts/images/20200715165456.webp)

To use non-default configurations with the TiDB started through IDEA as mentioned above, the simplest way is to modify this defaultConf.

## Summary

From this, you can see that checking whether a statement is supported, and whether it’s just syntax support or has a specific implementation, can be achieved with the described methods. You also learned how to view and modify default configurations, allowing you to conduct some verifications yourself. In the next article, I plan to introduce TiDB’s system variables.
