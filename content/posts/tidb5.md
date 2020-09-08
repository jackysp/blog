---
title:  "如何阅读 TiDB 的源代码（五）"
date: 2020-09-08T11:36:00+08:00
---

大家在使用 TiDB 时可能偶尔会遇到一些异常，比如 "Lost connection to MySQL server during query" 错误，此时代表客户端跟数据库连接已经断开了（非用户主动行为），
至于为什么会断开，通常有多种原因造成。本文试图从异常处理的角度，从代码层面分析一些常见的 TiDB 错误。
另外，有些异常并不是错误，而是执行缓慢，也就是性能问题，本文的后半段还会介绍常用的追踪性能的工具。

## Lost Connection

Lost Connection 一般有三种原因，

1. 客户端跟数据库之间连接超时（直连），或者客户端跟数据库的中间链路中的某个环节超时了，比如，客户端到 Proxy 或者 Proxy 到数据库出现了超时。
1. 连接在执行 SQL 时，遇到了 bug，此类 bug 一般都可以被 recover，进而不会导致整个 TiDB server 崩溃（panic）。
1. TiDB 自身崩溃，一般可能会由于使用内存过多，进而触发 OOM，或者用户主动杀掉 TiDB 导致，还有种可能就是存在 bug 但未被 recover，这种情况一般在后台线程中出现较多。

### Timeout

#### 直连超时

TiDB 支持与 MySQL 兼容的 `wait_timeout` 变量，默认值是 0，代表不设置超时，与 MySQL 的默认 8 小时不同。

![lost](/posts/images/20200908132926.png)

代码中唯一使用它的地方是 `getSessionVarsWaitTimeout`，在 connection Run 的位置，将它的值设置给 packet IO，如果变量非 0，则在每次读 `readPacket` 之前会设置 timeout，

![lost](/posts/images/20200908134545.png)

在客户端一直没有发过来数据的时间超过设定值之后，连接会断开。此时，会出现 "read packet timeout, close this connection" 的提示日志，并包含具体超时的时间。

#### 中间链路超时

另外一种情况是中间链路超时。正常的中间链路（proxy）超时，一般会返回给数据库一个 EOF 的错误，在旧的版本中会至少输出一个连接关闭的日志，

![lost](/posts/images/20200908141322.png)

新版 master 中，产品经理建议把这个日志改成了 debug 等级，一般也就不再输出了。

但是，新版中，增加了一个叫 `DisconnectionCounter` 的监控，

![lost](/posts/images/20200908141537.png)

![lost](/posts/images/20200908142131.png)

可以记录正常的连接断开和像这种异常的连接断开，算是对日志降级的一个补充。

### 被 recover 的 bug

TiDB "基本"可以做到把未知的 bug 导致的 panic 全都 recover 住。但是，一旦发生了数组越界、空指针引用或者一些有意的 panic，此时，不能保证当前出问题的 SQL 以及后来的 SQL 能给出正确的结果，因此，中断当前连接是一个明智的选择。

![lost](/posts/images/20200908143849.png)

此时，会出现 "connection running loop panic" 的错误日志，以及 lastSQL 字段，输出当前导致错误的 SQL。

### 未被 recover 的 panic

无论是一些未能被 recover 的 panic，还是系统级的 OOM 导致的 panic，都不会在 TiDB 的日志里留下日志。使用 Ansible、TiUP 等部署工具管理的 TiDB 集群，会自动拉起崩溃的 TiDB server，于是，日志里就又多了一条新的 Welcome，一般不留意可能会忽略，但是，监控里的 Uptime 也会显示 TiDB 的 Uptime 归零，所以，此类问题还是比较容易发现的。当然，最好是配上告警。

未能被 recover 的 panic 的输出就是 Golang 自身的标准输出，在部署工具中一般会重定向到 tidb_stderr.log 中，一些比较老的 Ansible 会每次重启覆盖这个文件，现在使用的都是追加的模式。

![lost](/posts/images/15992142135768.png)

但是，它还有些其他缺陷，例如，没有日期。因此没法跟 TiDB 输出的日志进行时间上的匹配。这个 [PR](https://github.com/pingcap/tidb/pull/18310) 实现了根据 PID 区分 tidb_stderr.log 的作用，只是还没有跟部署工具协调，暂时先关闭了。

得到这种标准 panic 输出，也可以用上一篇介绍的 panicparse 来解析 panic 结果，当然，一般其实，我们直接看最上面的一个栈就可以了。很明显上图中的例子是一个申请不到内存的错误导致的，也就是通常意义上的 OOM。至于，究竟是哪个 SQL 导致了 OOM，需要结合 TiDB 的日志，比如，查找一些疑似的使用资源特别多的 SQL，一般此类 SQL，会记录在带有 `expensive_query` 标记的日志中，大家可以自行 grep 日志来查看。在这就不举例了。

## Tracing

TiDB 自从 2.1 起就支持 tracing 功能了，只是一直没有被广泛的使用。个人认为有两个主要原因，

1. 初版的 tracing 功能只支持 json 格式，需要先输出出来，复制到 TiDB 自己特殊端口 host 的网页中粘贴查看，虽然是挺新颖的，但是，涉及的步骤太多，没有被广泛用起来。

    ![lost](/posts/images/20200908164836.png)
    ![lost](/posts/images/trace-view.png)

1. 还有一个问题是，tracing 有一种后知后觉的意味，也就是，只有当开发者知道哪里会出问题、会慢，才会主动为其增加打点，经常遇到的未知问题不能被覆盖，出现断档。

tracing 本身在框架支持好以后，增加埋点是相对简单的一件事情，只需要在希望埋点的位置加上如下一段代码即可：

![lost](/posts/images/20200908165442.png)

有感兴趣的同学其实可以自己根据需要给 TiDB 增加埋点，也是一个很好的上手体验机会。

后来，tracing 又增加了 format='row' 和 format='log' 功能，

![lost](/posts/images/20200908165729.png)

![lost](/posts/images/20200908165805.png)

个人更喜欢 format='log'，

### Tracing 跟 Explain (Analyze) 的区别

1. Tracing 是函数级的，Explain 是算子级的。Tracing 添加比较方便，粒度也更细，不需要必须是 plan 的一部分。
1. Tracing 可以 trace 任意 SQL，explain 只能看读数据的部分。以 Insert 为例，用 explain 基本什么都看不到，而 tracing 不仅能看，而且更细致，从 SQL 开始解析到整个事务自动提交都有记录。

![lost](/posts/images/20200908170040.png)
