---
title:  "如何阅读 TiDB 的源代码（四）"
date: 2020-07-31T10:58:00+08:00
---

本篇会介绍 TiDB 中的某些重点函数和日志的解读。

## 重点函数

重点函数的定义因人而异，所以，本章节内容偏向主观。

### execute

![func](/posts/images/20200812152326.png)

execute 是文本协议执行的必经之路。它也很好的展示了 SQL 处理的各个过程。

1. ParseSQL 解析 SQL，最终的实现是在 parser 中，按照前面第二篇介绍的规则进行 SQL 的解析，这里要注意，解析出来的 SQL 可能是单条，也可能是多条。
TiDB 本身支持 multi-SQL 特性，允许一次性执行多条 SQL
1. 解析完成后，会返回 stmtNodes 数组，在下面的 for 循环中挨个处理。首先要做的是 Compile，Compile 本身的核心是要做优化，生成 plan，顺着 Optimize 一路找进去就能够找到

    ![func](/posts/images/20200812153017.png)

    可以看到这里分了逻辑优化、物理优化等与常见其他数据库类似。

1. 最后是执行部分，executeStatement 其中 runStmt 是另外一个重点函数。

### runStmt

![func](/posts/images/20200731111912.png)

从 runStmt 的 call graph 看，这个函数几乎是所有 SQL 执行的必经之路，除了走 binary 协议的自动提交的点查语句，其他所有语句都会经过这个函数。
这个函数承担的责任是 SQL 的执行，不包括，SQL 解析、编译过程（binary 协议不需要重复解析 SQL，使用 plan cache 后也不需要编译 SQL）。

![func](/posts/images/20200731112400.png)

runStmt 函数核心部分时候如上的部分。从上到下依旧是：

1. checkTxnAborted

    当事务已经损坏不能再提交的时候，需要用户主动关闭事务，来结束整个已经损坏的事务。事务在执行时会遇到一些无法处理的错误，此时事务只能终止，
    此时，不能偷偷地关闭事务，因为用户可能会继续执行 SQL，并假设 SQL 还在事务内。这个函数的作用就是，让用户的后续所有 SQL 不执行，直接报错，
    直到，用户使用 rollback、commit 这种显示关闭事务的 SQL 才正常执行。

1. Exec

    执行 SQL，并返回 rs (result set) 结果集。

1. IsReadOnly

    当一个 SQL 执行完，我们需要判断它是否是一个只读的 SQL，如果是非只读 SQL，要将 SQL 暂存到事务的执行历史中。执行历史是在事务发生冲突等错误
    需要重试的时候用来重试事务的。这里之所以绕开了只读的 SQL，是因为事务的重试是在事务提交的阶段完成的，此时返回给客户端的只能是提交成功和失败，
    读取结果已经没有意义。

    同时，这部分还进行了 StmtCommit 和 StmtRollback。TiDB 是支持 MySQL 一样的语句提交和回滚，也就是，当事务中的某个语句执行失败，单条语句会原子地回滚，其他执行成功的语句，最终会随着事务提交。

    在 TiDB 中，是以两层 buffer 来实现的语句提交特性，也就是，事务有自己的 buffer，语句也有自己的，当语句执行成功后，会把 buffer 刷入事务 buffer 进行融合。当语句执行失败后，语句 buffer 会被丢弃。这就保证了语句提交的原子性。当然，语句提交可能失败，如果失败的话，整个事务 buffer 将不可用，事务进入只能被回滚的阶段。

1. finishStmt

    当一个语句执行完成，是否该进行提交呢？这取决于是否是显示开启的事务，也就是 begin、start transaction 显示启动事务，再就是 autocommit 的是否开启？finishStmt 的作用就是在执行完语句后，检查是否该提交了，根据以上情况。相当于对每个语句结束进行一些清理和检查。

1. pending 部分

    TiDB 中有些 SQL 是不需要启动事务的，比如 set 语句，但是，语句被解析之前，数据库是不知道该语句是否需要启动事务。在 TiDB 中启动一个事务的 latency 也比较高，因为需要去 PD 获取一个 tso，因此，TiDB 有异步获取 tso 的优化，也就是，无论最终是否需要启动事务，都先准备好 tso，所以，当语句确实不需要 tso 时，也就是事务没有被激活，一直处于 pending 状态，此时，需要关闭这个 pending 中的事务。

## 日志

我们先进一段日志，这段日志是 TiDB 初次启动时的日志，这里分了几个部分：

```text
[2020/08/12 16:12:07.282 +08:00] [INFO] [printer.go:42] ["Welcome to TiDB."] ["Release Version"=None] [Edition=None] ["Git Commit Hash"=None] ["Git Branch"=None] ["UTC Build Time"=None] [GoVersion=go1.15] ["Race Enabled"=false] ["Check Table Before Drop"=false] ["TiKV Min Version"=v3.0.0-60965b006877ca7234adaced7890d7b029ed1306]
[2020/08/12 16:12:07.300 +08:00] [INFO] [printer.go:56] ["loaded config"] [config="{\"host\":\"0.0.0.0\",\"advertise-address\":\"0.0.0.0\",\"port\":4000,\"cors\":\"\",\"store\":\"mocktikv\",\"path\":\"/tmp/tidb\",\"socket\":\"\",\"lease\":\"45s\",\"run-ddl\":true,\"split-table\":true,\"token-limit\":1000,\"oom-use-tmp-storage\":true,\"tmp-storage-path\":\"C:\\\\Users\\\\yushu\\\\AppData\\\\Local\\\\Temp\\\\S-1-5-21-4064392927-3477209728-2136073142-1001_tidb\\\\MC4wLjAuMDo0MDAwLzAuMC4wLjA6MTAwODA=\\\\tmp-storage\",\"oom-action\":\"log\",\"mem-quota-query\":1073741824,\"tmp-storage-quota\":-1,\"enable-streaming\":false,\"enable-batch-dml\":false,\"lower-case-table-names\":2,\"server-version\":\"\",\"log\":{\"level\":\"info\",\"format\":\"text\",\"disable-timestamp\":null,\"enable-timestamp\":null,\"disable-error-stack\":null,\"enable-error-stack\":null,\"file\":{\"filename\":\"\",\"max-size\":300,\"max-days\":0,\"max-backups\":0},\"enable-slow-log\":true,\"slow-query-file\":\"tidb-slow.log\",\"slow-threshold\":300,\"expensive-threshold\":10000,\"query-log-max-len\":4096,\"record-plan-in-slow-log\":1},\"security\":{\"skip-grant-table\":false,\"ssl-ca\":\"\",\"ssl-cert\":\"\",\"ssl-key\":\"\",\"require-secure-transport\":false,\"cluster-ssl-ca\":\"\",\"cluster-ssl-cert\":\"\",\"cluster-ssl-key\":\"\",\"cluster-verify-cn\":null},\"status\":{\"status-host\":\"0.0.0.0\",\"metrics-addr\":\"\",\"status-port\":10080,\"metrics-interval\":15,\"report-status\":true,\"record-db-qps\":false},\"performance\":{\"max-procs\":0,\"max-memory\":0,\"stats-lease\":\"3s\",\"stmt-count-limit\":5000,\"feedback-probability\":0.05,\"query-feedback-limit\":1024,\"pseudo-estimate-ratio\":0.8,\"force-priority\":\"NO_PRIORITY\",\"bind-info-lease\":\"3s\",\"txn-total-size-limit\":104857600,\"tcp-keep-alive\":true,\"cross-join\":true,\"run-auto-analyze\":true,\"agg-push-down-join\":false,\"committer-concurrency\":16,\"max-txn-ttl\":600000},\"prepared-plan-cache\":{\"enabled\":false,\"capacity\":100,\"memory-guard-ratio\":0.1},\"opentracing\":{\"enable\":false,\"rpc-metrics\":false,\"sampler\":{\"type\":\"const\",\"param\":1,\"sampling-server-url\":\"\",\"max-operations\":0,\"sampling-refresh-interval\":0},\"reporter\":{\"queue-size\":0,\"buffer-flush-interval\":0,\"log-spans\":false,\"local-agent-host-port\":\"\"}},\"proxy-protocol\":{\"networks\":\"\",\"header-timeout\":5},\"tikv-client\":{\"grpc-connection-count\":4,\"grpc-keepalive-time\":10,\"grpc-keepalive-timeout\":3,\"commit-timeout\":\"41s\",\"max-batch-size\":128,\"overload-threshold\":200,\"max-batch-wait-time\":0,\"batch-wait-size\":8,\"enable-chunk-rpc\":true,\"region-cache-ttl\":600,\"store-limit\":0,\"store-liveness-timeout\":\"120s\",\"copr-cache\":{\"enable\":false,\"capacity-mb\":1000,\"admission-max-result-mb\":10,\"admission-min-process-ms\":5}},\"binlog\":{\"enable\":false,\"ignore-error\":false,\"write-timeout\":\"15s\",\"binlog-socket\":\"\",\"strategy\":\"range\"},\"compatible-kill-query\":false,\"plugin\":{\"dir\":\"\",\"load\":\"\"},\"pessimistic-txn\":{\"enable\":true,\"max-retry-count\":256},\"check-mb4-value-in-utf8\":true,\"max-index-length\":3072,\"alter-primary-key\":false,\"treat-old-version-utf8-as-utf8mb4\":true,\"enable-table-lock\":false,\"delay-clean-table-lock\":0,\"split-region-max-num\":1000,\"stmt-summary\":{\"enable\":true,\"enable-internal-query\":false,\"max-stmt-count\":200,\"max-sql-length\":4096,\"refresh-interval\":1800,\"history-size\":24},\"repair-mode\":false,\"repair-table-list\":[],\"isolation-read\":{\"engines\":[\"tikv\",\"tiflash\",\"tidb\"]},\"max-server-connections\":0,\"new_collations_enabled_on_first_bootstrap\":false,\"experimental\":{\"allow-auto-random\":false,\"allow-expression-index\":false}}"]
```

1. 启动必输出的 Welcome to TiDB、git hash、Golang 版本等等
1. 实际载入的配置（这段其实非常难看）

剩下是一些常规的启动日志，流程可参考第一篇介绍的 main 函数部分，这里主要输出的是初始的系统表创建过程。

```text
[2020/08/12 16:12:07.300 +08:00] [INFO] [main.go:341] ["disable Prometheus push client"]
[2020/08/12 16:12:07.300 +08:00] [INFO] [store.go:68] ["new store"] [path=mocktikv:///tmp/tidb]
[2020/08/12 16:12:07.300 +08:00] [INFO] [systime_mon.go:25] ["start system time monitor"]
[2020/08/12 16:12:07.310 +08:00] [INFO] [store.go:74] ["new store with retry success"]
[2020/08/12 16:12:07.310 +08:00] [INFO] [tidb.go:71] ["new domain"] [store=8d19232e-a273-4e31-ba9b-a3467998345c] ["ddl lease"=45s] ["stats lease"=3s]
[2020/08/12 16:12:07.315 +08:00] [INFO] [ddl.go:321] ["[ddl] start DDL"] [ID=0e1bd28e-03ed-4900-bf71-f58b3b9d954a] [runWorker=true]
[2020/08/12 16:12:07.315 +08:00] [INFO] [ddl.go:309] ["[ddl] start delRangeManager OK"] ["is a emulator"=true]
[2020/08/12 16:12:07.315 +08:00] [INFO] [ddl_worker.go:130] ["[ddl] start DDL worker"] [worker="worker 1, tp general"]
[2020/08/12 16:12:07.315 +08:00] [INFO] [ddl_worker.go:130] ["[ddl] start DDL worker"] [worker="worker 2, tp add index"]
[2020/08/12 16:12:07.315 +08:00] [INFO] [delete_range.go:133] ["[ddl] start delRange emulator"]
[2020/08/12 16:12:07.317 +08:00] [INFO] [domain.go:144] ["full load InfoSchema success"] [usedSchemaVersion=0] [neededSchemaVersion=0] ["start time"=2.0015ms]
[2020/08/12 16:12:07.317 +08:00] [INFO] [domain.go:368] ["full load and reset schema validator"]
[2020/08/12 16:12:07.317 +08:00] [INFO] [tidb.go:199] ["rollbackTxn for ddl/autocommit failed"]
[2020/08/12 16:12:07.317 +08:00] [WARN] [session.go:1040] ["run statement failed"] [schemaVersion=0] [error="[schema:1049]Unknown database 'mysql'"] [session="{\n  \"currDBName\": \"\",\n  \"id\": 0,\n  \"status\": 2,\n  \"strictMode\": true,\n  \"user\": null\n}"]
[2020/08/12 16:12:07.318 +08:00] [WARN] [session.go:1136] ["compile SQL failed"] [error="[schema:1146]Table 'mysql.tidb' doesn't exist"] [SQL="SELECT HIGH_PRIORITY VARIABLE_VALUE FROM mysql.tidb WHERE VARIABLE_NAME=\"bootstrapped\""]
[2020/08/12 16:12:07.318 +08:00] [INFO] [session.go:2121] ["CRUCIAL OPERATION"] [conn=0] [schemaVersion=0] [cur_db=] [sql="CREATE DATABASE IF NOT EXISTS test"] [user=]
[2020/08/12 16:12:07.320 +08:00] [INFO] [ddl_worker.go:253] ["[ddl] add DDL jobs"] ["batch count"=1] [jobs="ID:2, Type:create schema, State:none, SchemaState:none, SchemaID:1, TableID:0, RowCount:0, ArgLen:1, start time: 2020-08-12 16:12:07.318 +0800 CST, Err:<nil>, ErrCount:0, SnapshotVersion:0; "]
[2020/08/12 16:12:07.320 +08:00] [INFO] [ddl.go:500] ["[ddl] start DDL job"] [job="ID:2, Type:create schema, State:none, SchemaState:none, SchemaID:1, TableID:0, RowCount:0, ArgLen:1, start time: 2020-08-12 16:12:07.318 +0800 CST, Err:<nil>, ErrCount:0, SnapshotVersion:0"] [query="CREATE DATABASE IF NOT EXISTS test"]
[2020/08/12 16:12:07.320 +08:00] [INFO] [ddl_worker.go:568] ["[ddl] run DDL job"] [worker="worker 1, tp general"] [job="ID:2, Type:create schema, State:none, SchemaState:none, SchemaID:1, TableID:0, RowCount:0, ArgLen:0, start time: 2020-08-12 16:12:07.318 +0800 CST, Err:<nil>, ErrCount:0, SnapshotVersion:0"]
[2020/08/12 16:12:07.322 +08:00] [INFO] [domain.go:144] ["full load InfoSchema success"] [usedSchemaVersion=0] [neededSchemaVersion=1] ["start time"=1.0003ms]
[2020/08/12 16:12:07.322 +08:00] [INFO] [domain.go:368] ["full load and reset schema validator"]
[2020/08/12 16:12:07.324 +08:00] [INFO] [ddl_worker.go:757] ["[ddl] wait latest schema version changed"] [worker="worker 1, tp general"] [ver=1] ["take time"=3.0094ms] [job="ID:2, Type:create schema, State:done, SchemaState:public, SchemaID:1, TableID:0, RowCount:0, ArgLen:1, start time: 2020-08-12 16:12:07.318 +0800 CST, Err:<nil>, ErrCount:0, SnapshotVersion:0"]
[2020/08/12 16:12:07.324 +08:00] [INFO] [ddl_worker.go:359] ["[ddl] finish DDL job"] [worker="worker 1, tp general"] [job="ID:2, Type:create schema, State:synced, SchemaState:public, SchemaID:1, TableID:0, RowCount:0, ArgLen:0, start time: 2020-08-12 16:12:07.318 +0800 CST, Err:<nil>, ErrCount:0, SnapshotVersion:0"]
[2020/08/12 16:12:07.325 +08:00] [INFO] [ddl.go:532] ["[ddl] DDL job is finished"] [jobID=2]
[2020/08/12 16:12:07.325 +08:00] [INFO] [domain.go:619] ["performing DDL change, must reload"]
[2020/08/12 16:12:07.325 +08:00] [INFO] [session.go:2121] ["CRUCIAL OPERATION"] [conn=0] [schemaVersion=1] [cur_db=] [sql="CREATE DATABASE IF NOT EXISTS mysql;"] [user=]
[2020/08/12 16:12:07.325 +08:00] [INFO] [ddl_worker.go:253] ["[ddl] add DDL jobs"] ["batch count"=1] [jobs="ID:4, Type:create schema, State:none, SchemaState:none, SchemaID:3, TableID:0, RowCount:0, ArgLen:1, start time: 2020-08-12 16:12:07.325 +0800 CST, Err:<nil>, ErrCount:0, SnapshotVersion:0; "]
[2020/08/12 16:12:07.325 +08:00] [INFO] [ddl.go:500] ["[ddl] start DDL job"] [job="ID:4, Type:create schema, State:none, SchemaState:none, SchemaID:3, TableID:0, RowCount:0, ArgLen:1, start time: 2020-08-12 16:12:07.325 +0800 CST, Err:<nil>, ErrCount:0, SnapshotVersion:0"] [query="CREATE DATABASE IF NOT EXISTS mysql;"]
[2020/08/12 16:12:07.326 +08:00] [INFO] [ddl_worker.go:568] ["[ddl] run DDL job"] [worker="worker 1, tp general"] [job="ID:4, Type:create schema, State:none, SchemaState:none, SchemaID:3, TableID:0, RowCount:0, ArgLen:0, start time: 2020-08-12 16:12:07.325 +0800 CST, Err:<nil>, ErrCount:0, SnapshotVersion:0"]
[2020/08/12 16:12:07.326 +08:00] [INFO] [domain.go:126] ["diff load InfoSchema success"] [usedSchemaVersion=1] [neededSchemaVersion=2] ["start time"=0s] [tblIDs="[]"]
[2020/08/12 16:12:07.329 +08:00] [INFO] [ddl_worker.go:757] ["[ddl] wait latest schema version changed"] [worker="worker 1, tp general"] [ver=2] ["take time"=2.9965ms] [job="ID:4, Type:create schema, State:done, SchemaState:public, SchemaID:3, TableID:0, RowCount:0, ArgLen:1, start time: 2020-08-12 16:12:07.325 +0800 CST, Err:<nil>, ErrCount:0, SnapshotVersion:0"]
[2020/08/12 16:12:07.329 +08:00] [INFO] [ddl_worker.go:359] ["[ddl] finish DDL job"] [worker="worker 1, tp general"] [job="ID:4, Type:create schema, State:synced, SchemaState:public, SchemaID:3, TableID:0, RowCount:0, ArgLen:0, start time: 2020-08-12 16:12:07.325 
```

因为 DDL 日志非常的多，TiDB 日志基本记录了 DDL 执行的每一个步骤，所以，我这里截断了这部分日志。但是，基本的脉络是可以梳理一下的，首先，DDL 执行
是从 ddl_api 中发起的，此时会记录 `["CRUCIAL OPERATION"]` 样式的日志，DDL 属于关键操作，所以属于 CRUCIAL 类型日志。然后，可以看到由 `[ddl] add DDL jobs`、`[ddl] start DDL job`、`[ddl] run DDL job`、`[ddl] finish DDL job`、`[ddl] DDL job is finished` 这样一系列的以 ddl 关键字
串起来的日志，标志着 DDL owner 获取到一个 job 到最终执行完成的过程。而且他们都有一个唯一的 job ID，在日志中可以依靠类似 `jobs="ID:2` 的字样来串联一个 DDL。

```text
[2020/08/12 16:12:07.518 +08:00] [INFO] [server.go:235] ["server is running MySQL protocol"] [addr=0.0.0.0:4000]
[2020/08/12 16:12:07.518 +08:00] [INFO] [http_status.go:80] ["for status and metrics report"] ["listening on addr"=0.0.0.0:10080]
[2020/08/12 16:12:07.520 +08:00] [INFO] [domain.go:1015] ["init stats info time"] ["take time"=3.0126ms]
[2020/08/12 16:15:41.482 +08:00] [INFO] [server.go:388] ["new connection"] [conn=1] [remoteAddr=127.0.0.1:64888]
[2020/08/12 21:03:19.954 +08:00] [INFO] [server.go:391] ["connection closed"] [conn=1]
```

再之后，直到 `server is running MySQL protocol` 出现才意味着，TiDB 可以对外提供服务了。后面创建和关闭每个连接都有对应的 `new connection` 和 `connection closed` 的日志，当然也有它们对应的 connection ID，这个 ID 对于一个 TiDB 来说也是唯一的。可以在日志重用 `conn=1` 这个关键字串联起来上下文。

### 堆栈的日志

大部分 TiDB 的 SQL 报错（除了 duplicate entry 和 syntax error）都会输出完整的堆栈信息，由于统一日志格式的要求，堆栈现在长得很难看。。。

```text
[2020/08/12 21:05:18.555 +08:00] [ERROR] [conn.go:728] ["command dispatched failed"] [conn=2] [connInfo="id:2, addr:127.0.0.1:60628 status:10, collation:utf8mb4_0900_ai_ci, user:root"] [command=Query] [status="inTxn:0, autocommit:1"] [sql="insert into t value (i1)"] [txn_mode=OPTIMISTIC] [err="[planner:1054]Unknown column 'i1' in 'field list'\ngithub.com/pingcap/errors.AddStack\n\tC:/Users/yushu/go/pkg/mod/github.com/pingcap/errors@v0.11.5-0.20190809092503-95897b64e011/errors.go:174\ngithub.com/pingcap/parser/terror.(*Error).GenWithStackByArgs\n\tC:/Users/yushu/go/pkg/mod/github.com/pingcap/parser@v0.0.0-20200525110646-f45c2cee1dca/terror/terror.go:243\ngithub.com/pingcap/tidb/planner/core.(*expressionRewriter).toColumn\n\tC:/Users/yushu/work/tidb/planner/core/expression_rewriter.go:1597\ngithub.com/pingcap/tidb/planner/core.(*expressionRewriter).Leave\n\tC:/Users/yushu/work/tidb/planner/core/expression_rewriter.go:940\ngithub.com/pingcap/parser/ast.(*ColumnName).Accept\n\tC:/Users/yushu/go/pkg/mod/github.com/pingcap/parser@v0.0.0-20200525110646-f45c2cee1dca/ast/expressions.go:526\ngithub.com/pingcap/parser/ast.(*ColumnNameExpr).Accept\n\tC:/Users/yushu/go/pkg/mod/github.com/pingcap/parser@v0.0.0-20200525110646-f45c2cee1dca/ast/expressions.go:588\ngithub.com/pingcap/tidb/planner/core.(*PlanBuilder).rewriteExprNode\n\tC:/Users/yushu/work/tidb/planner/core/expression_rewriter.go:170\ngithub.com/pingcap/tidb/planner/core.(*PlanBuilder).rewriteWithPreprocess\n\tC:/Users/yushu/work/tidb/planner/core/expression_rewriter.go:119\ngithub.com/pingcap/tidb/planner/core.(*PlanBuilder).buildValuesListOfInsert\n\tC:/Users/yushu/work/tidb/planner/core/planbuilder.go:2280\ngithub.com/pingcap/tidb/planner/core.(*PlanBuilder).buildInsert\n\tC:/Users/yushu/work/tidb/planner/core/planbuilder.go:2048\ngithub.com/pingcap/tidb/planner/core.(*PlanBuilder).Build\n\tC:/Users/yushu/work/tidb/planner/core/planbuilder.go:481\ngithub.com/pingcap/tidb/planner.optimize\n\tC:/Users/yushu/work/tidb/planner/optimize.go:150\ngithub.com/pingcap/tidb/planner.Optimize\n\tC:/Users/yushu/work/tidb/planner/optimize.go:63\ngithub.com/pingcap/tidb/executor.(*Compiler).Compile\n\tC:/Users/yushu/work/tidb/executor/compiler.go:61\ngithub.com/pingcap/tidb/session.(*session).execute\n\tC:/Users/yushu/work/tidb/session/session.go:1129\ngithub.com/pingcap/tidb/session.(*session).Execute\n\tC:/Users/yushu/work/tidb/session/session.go:1080\ngithub.com/pingcap/tidb/server.(*TiDBContext).Execute\n\tC:/Users/yushu/work/tidb/server/driver_tidb.go:248\ngithub.com/pingcap/tidb/server.(*clientConn).handleQuery\n\tC:/Users/yushu/work/tidb/server/conn.go:1265\ngithub.com/pingcap/tidb/server.(*clientConn).dispatch\n\tC:/Users/yushu/work/tidb/server/conn.go:899\ngithub.com/pingcap/tidb/server.(*clientConn).Run\n\tC:/Users/yushu/work/tidb/server/conn.go:713\ngithub.com/pingcap/tidb/server.(*Server).onConn\n\tC:/Users/yushu/work/tidb/server/server.go:415\nruntime.goexit\n\tC:/Go/src/runtime/asm_amd64.s:1374"]
```

对于这一坨堆栈，相信没人有喜欢看。所以，我们要把他们粘出来放到 vim 中，执行 `%s/\\n/\r/g` 和 `%s/\\t/    /g` 才能变成 Golang 标准栈的样子

![func](/posts/images/20200812211203.png)

这时候看到挂在哪个模块里，比如这里是 plan 的部分，就可以找相应的同学支持了。

至此，重点函数和关键日志的解析（启动、DDL、连接、错误栈）就跟大家介绍到这里了。
