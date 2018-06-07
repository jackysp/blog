---
title:  "如何看待 CMU DB Group 的 OLTP-Bench"
date: 2018-02-23T22:21:06+08:00
---

# OLTP-Bench 介绍

OLTP-Bench 是 CMU 的 DB Group 开源的一套针对 OLTP 场景的 Benchmark 工具平台。设计初衷是提供一个简单易用、容易扩展的测试平台。

它通过 jdbc 接口连接数据库，支持的测试集有：

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

项目详细介绍在 http://db.cs.cmu.edu/projects/oltp-bench/ ， github 页面在 https://github.com/oltpbenchmark/oltpbench 。

项目介绍页里有作者们在这个项目发表的 3 篇论文，其中 2013 年的是最重要的一篇，该篇也在 github 页面上给了链接。

从 github 页面上看，该工程的关注度不算高，近期也不算活跃。 issue 和 pr 大多来自 cmu 内部。

# OLTP-Bench: An Extensible Testbed for Benchmarking Relational Databases

这篇《 OLTP-Bench: An Extensible Testbed for Benchmarking Relational Databases 》论文可以看作是该项目的最详细介绍。

第一二章，作者介绍了做这个框架的起因，就是要整合多个测试集在一起，并提供一些单纯的 benchmark 工具没有的功能，同时提供很好的扩展性，这样把开源出去，吸引开发者是他们更容易在上面补充更多的数据库的支持。

结合 github 上的动态，可以看出来，这种扩展方便在于增加数据库支持上的方便，而不是增加测试集的方便上。不过目前支持的测试集也是比较多的。

第三章是架构设计介绍。重点介绍了测试集的管理，负载生成器， SQL 语法的转换，多客户端（可能类似于多个 sysbench 对一个 MySQL 加压），结果收集。

第四章是对支持的测试集的介绍。我只熟悉 TPCC 和 YCSB 。作者是按照三个角度来划分的。

1. 侧重交易行为的， tpcc 、 smallbank
1. 互联网应用， linkbench 、 wikipedia
1. 专项测试， ycsb 、 sibench

更详细的内容可见下表：
[table]

第五章介绍了 demo 的部署环境，后面要介绍这个 demo 的一些效果。

第六章通过上一章提的 demo 进行特性介绍。下面逐一分析：

1. 速率控制。 benchmark 工具进行速率控制，我觉得是一件很奇怪的事情。常规认识里，应该是能把性能跑多高就跑多高，看看系统的上限。这里文中举的例子是用 Wikipedia 测试集，每 10 秒增加 25 tps 来看数据库时延的变化。
1. 给同一个测试集里不同事务打标记，分别来统计他们。这里以 TPCC 为例，把交易里不同的环节的事务分别来统计。
1. 改变负载内容，如将只读负载改为只写。
1. 改变负载的随机数方法。
1. 监控数据库的同时，监控服务器的状态。需要在服务器上部署一个 OLTP-Bench 的 monitor 。
1. 同时跑多个测试集。如跑 TPCC 的同时跑 YCSB 。
1. 多客户端，第三章提到过。
1. 可重复性。证明 OLTP-Bench 的结果是真实可靠的，作者拿这套工具里的 SIBench 在差不多配置的机器上测了下 PG 的 SSI 的性能。结果最终跟 PG 的 SSI 论文中给出的性能一致。

小结一下，速率控制和给不同事务以标记这两点比较新颖，其余特性只能说并不特别。

第七章所讲的是个人感觉整篇文章里最有价值的地方。在云环境下，用户可能只有数据库的连接方法，没有查看数据库服务器的方法。这时候用户想知道哪家云数据库服务性价比更高，同一家下哪个配置性价比更高就比较难了。因为计费方式包括了 CPU 、存储、网络等方面，很多架构下数据库主备间的同步开销等都是计算在内的。因此用 benchmark 工具得到性能后，再通过产生的费用得到性价比，是云的大环境下非常值得做的事情。本章就在不同角度下进行了对比，不同的服务商，服务商里不同的配置，同一配置下不同的数据库，给出了性价比的结果。

第八章，作者对比 OLTP-Bench 与其他类似工具的区别，总之，是给了很好的自评。

第九章，作者许诺了一下将来的要做的特性，有：纯 NoSQL 的支持，支持更多的数据库自有的 SQL 语法，从生产环境得到数据分布转而生成符合生产环境的负载（这个如果有，值得期待），存储过程。

总结，看论文的话，就像作者说的，这是个集成框架，易用性和扩展性才是它的关键。

# 使用总结

OLTP-Bench 安装和使用相对简单，尤其是安装部署，由于其跨平台的特性，体验上比传统的 tpcc 、 sysbench 要好。使用上由于给出了大量的测试配置的模版，也很容易上手。简单修改配置文件即可开始测试。
并且测试结果稳定。某些论文中提及的特性的开启方式尚待挖掘，如服务器状态监控。

我分别在 MySQL 5.7 和 TiDB 上测试了全部 15 个测试集，得到以下结果：
[table]

可见其可用性还是可以的。至于进行二次开发的难易程度，应该偏简单，毕竟整个 OLTP-Bench 工程的代码总量并不大，在 4 万左右。

# 其他

* tpch: 从代码看，框架里是有 tpch 的支持，实际测试了一下，并不可用，应该一直没有完善，所以没有放到 README 里。
* 论文里第九章提到的下一步工作，尤其是“从生产环境得到数据分布转而生成符合生产环境的负载”，在代码里并没有看到，应该还没做。