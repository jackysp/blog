---
title: "How to Read TiDB Source Code (Part 4)"
date: 2020-07-31T10:58:00+08:00
---

This article will introduce some key functions and the interpretation of logs in TiDB.

## Key Functions

The definition of key functions varies from person to person, so the content of this section is subjective.

### execute

![func](/posts/images/20200812152326.png)

The `execute` function is the necessary pathway for text protocol execution. It also nicely demonstrates the various processes of SQL handling.

1. ParseSQL analyzes the SQL. The final implementation is in the parser, where SQL is parsed according to the rules introduced in the second article. Note that the parsed SQL may be a single statement or multiple statements. TiDB itself supports the multi-SQL feature, allowing multiple SQL statements to be executed at once.
1. After parsing, a `stmtNodes` array is returned, which is processed one-by-one in the for loop below. The first step is to compile, where the core of compile is optimization, generating a plan. By following the `Optimize` function, you can find logic similar to logical and physical optimization found in other common databases.

    ![func](/posts/images/20200812153017.png)

1. The last part is execution, where `executeStatement` and particularly the `runStmt` function are key functions.

### runStmt

![func](/posts/images/20200731111912.png)

Judging from the call graph of `runStmt`, this function is almost the mandatory pathway for all SQL execution. Except for point query statements using the binary protocol with automatic commit, all other statements go through this function. This function is responsible for executing SQL, excluding SQL parsing and compilation (the binary protocol does not need repeated SQL parsing, nor does SQL compilation require plan caching).

![func](/posts/images/20200731112400.png)

The core part of the `runStmt` function is as shown above. From top to bottom:

1. checkTxnAborted

    When a transaction is already corrupted and cannot be committed, the user must actively close the transaction to end the already corrupted transaction. During execution, transactions may encounter errors that cannot be handled and must be terminated. The transaction cannot be silently closed because the user may continue to execute SQL and assume it is still within the transaction. This function ensures that all subsequent SQL commands by the user are not executed and directly return an error until the user uses rollback or commit to explicitly close the transaction for normal execution.

1. Exec

    Execute the SQL and return the result set (rs).

1. IsReadOnly

    After executing a SQL, it's necessary to determine whether it is a read-only SQL. If it is not read-only, it must be temporarily stored in the transaction's execution history. This execution history is used when a transaction conflict or other errors require the transaction to be retried. Read-only SQL is bypassed because the retry of the transaction is done during the commit phase, and at this point, the only feedback to the client can be success or failure of the commit; reading results is meaningless.

    This section also includes `StmtCommit` and `StmtRollback`. TiDB supports MySQL-like statement commits and rollbacks—if a statement fails during a transaction, that single statement will be atomically rolled back, while other successfully executed statements will eventually commit with the transaction.

    In TiDB, the feature of statement commit is implemented with a two-layer buffer: both the transaction and the statement have their own buffers. After a statement executes successfully, the statement’s buffer is merged into the transaction buffer. If a statement fails, the statement’s buffer is discarded, thus ensuring the atomicity of statement commits. Of course, a statement commit may fail, in which case the entire transaction buffer becomes unusable, and the transaction can only be rolled back.

1. finishStmt

    Once a statement is executed, should it be committed? This depends on whether the transaction was explicitly started (i.e., with `begin` or `start transaction`) and whether autocommit is enabled. The role of `finishStmt` is to, post-execution, check if it should be committed based on the above conditions. It's essentially for cleaning up and checking after each statement execution.

1. pending section

    Some SQLs in TiDB do not require a transaction (e.g., the `set` statement). However, before parsing, the database doesn’t know whether the statement requires a transaction. The latency of starting a transaction in TiDB is relatively high because it requires obtaining a TSO (timestamp oracle) from PD. TiDB has an optimization to asynchronously obtain a TSO, meaning a TSO is prepared regardless of whether a transaction is eventually needed. If a statement indeed doesn’t require a TSO and a transaction is not activated, remaining in a pending status, the pending transaction must be closed.

## Logs

Let's first look at a section of logs from TiDB at initial startup, divided into several parts:

```text
[2020/08/12 16:12:07.282 +08:00] [INFO] [printer.go:42] ["Welcome to TiDB."] ["Release Version"=None] [Edition=None] ["Git Commit Hash"=None] ["Git Branch"=None] ["UTC Build Time"=None] [GoVersion=go1.15] ["Race Enabled"=false] ["Check Table Before Drop"=false] ["TiKV Min Version"=v3.0.0-60965b006877ca7234adaced7890d7b029ed1306]
[2020/08/12 16:12:07.300 +08:00] [INFO] [printer.go:56] ["loaded config"] [config="{\"host\":\"0.0.0.0\",\"advertise-address\":\"0.0.0.0\",\"port\":4000,\"cors\":\"\",\"store\":\"mocktikv\",\"path\":\"/tmp/tidb\",\"socket\":\"\",\"lease\":\"45s\",\"run-ddl\":true,\"split-table\":true,\"token-limit\":1000,\"oom-use-tmp-storage\":true,\"tmp-storage-path\":\"C:\\\\Users\\\\yushu\\\\AppData\\\\Local\\\\Temp\\\\S-1-5-21-4064392927-3477209728-2136073142-1001_tidb\\\\MC4wLjAuMDo0MDAwLzAuMC4wLjA6MTAwODA=\\\\tmp-storage\",\"oom-action\":\"log\",\"mem-quota-query\":1073741824,\"tmp-storage-quota\":-1,\"enable-streaming\":false,\"enable-batch-dml\":false,\"lower-case-table-names\":2,\"server-version\":\"\",\"log\":{\"level\":\"info\",\"format\":\"text\",\"disable-timestamp\":null,\"enable-timestamp\":null,\"disable-error-stack\":null,\"enable-error-stack\":null,\"file\":{\"filename\":\"\",\"max-size\":300,\"max-days\":0,\"max-backups\":0},\"enable-slow-log\":true,\"slow-query-file\":\"tidb-slow.log\",\"slow-threshold\":300,\"expensive-threshold\":10000,\"query-log-max-len\":4096,\"record-plan-in-slow-log\":1},\"security\":{\"skip-grant-table\":false,\"ssl-ca\":\"\",\"ssl-cert\":\"\",\"ssl-key\":\"\",\"require-secure-transport\":false,\"cluster-ssl-ca\":\"\",\"cluster-ssl-cert\":\"\",\"cluster-ssl-key\":\"\",\"cluster-verify-cn\":null},\"status\":{\"status-host\":\"0.0.0.0\",\"metrics-addr\":\"\",\"status-port\":10080,\"metrics-interval\":15,\"report-status\":true,\"record-db-qps\":false},\"performance\":{\"max-procs\":0,\"max-memory\":0,\"stats-lease\":\"3s\",\"stmt-count-limit\":5000,\"feedback-probability\":0.05,\"query-feedback-limit\":1024,\"pseudo-estimate-ratio\":0.8,\"force-priority\":\"NO_PRIORITY\",\"bind-info-lease\":\"3s\",\"txn-total-size-limit\":104857600,\"tcp-keep-alive\":true,\"cross-join\":true,\"run-auto-analyze\":true,\"agg-push-down-join\":false,\"committer-concurrency\":16,\"max-txn-ttl\":600000},\"prepared-plan-cache\":{\"enabled\":false,\"capacity\":100,\"memory-guard-ratio\":0.1},\"opentracing\":{\"enable\":false,\"rpc-metrics\":false,\"sampler\":{\"type\":\"const\",\"param\":1,\"sampling-server-url\":\"\",\"max-operations\":0,\"sampling-refresh-interval\":0},\"reporter\":{\"queue-size\":0,\"buffer-flush-interval\":0,\"log-spans\":false,\"local-agent-host-port\":\"\"}},\"proxy-protocol\":{\"networks\":\"\",\"header-timeout\":5},\"tikv-client\":{\"grpc-connection-count\":4,\"grpc-keepalive-time\":10,\"grpc-keepalive-timeout\":3,\"commit-timeout\":\"41s\",\"max-batch-size\":128,\"overload-threshold\":200,\"max-batch-wait-time\":0,\"batch-wait-size\":8,\"enable-chunk-rpc\":true,\"region-cache-ttl\":600,\"store-limit\":0,\"store-liveness-timeout\":\"120s\",\"copr-cache\":{\"enable\":false,\"capacity-mb\":1000,\"admission-max-result-mb\":10,\"admission-min-process-ms\":5}},\"binlog\":{\"enable\":false,\"ignore-error\":false,\"write-timeout\":\"15s\",\"binlog-socket\":\"\",\"strategy\":\"range\"},\"compatible-kill-query\":false,\"plugin\":{\"dir\":\"\",\"load\":\"\"},\"pessimistic-txn\":{\"enable\":true,\"max-retry-count\":256},\"check-mb4-value-in-utf8\":true,\"max-index-length\":3072,\"alter-primary-key\":false,\"treat-old-version-utf8-as-utf8mb4\":true,\"enable-table-lock\":false,\"delay-clean-table-lock\":0,\"split-region-max-num\":1000,\"stmt-summary\":{\"enable\":true,\"enable-internal-query\":false,\"max-stmt-count\":200,\"max-sql-length\":4096,\"refresh-interval\":1800,\"history-size\":24},\"repair-mode\":false,\"repair-table-list\":[],\"isolation-read\":{\"engines\":[\"tikv\",\"tiflash\",\"tidb\"]},\"max-server-connections\":0,\"new_collations_enabled_on_first_bootstrap\":false,\"experimental\":{\"allow-auto-random\":false,\"allow-expression-index\":false}}"]
```

1. Mandatory startup outputs: "Welcome to TiDB," git hash, Golang version, etc.
1. Actually loaded configuration (this section is somewhat difficult to read)

The remainder are some routine startup logs. The process can be referenced from the main function section introduced in the first article, mainly outputting the initial system table creation process.

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
```Here is the translation of the provided text:

---

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

Because DDL logs are very numerous, the TiDB logs basically record each step of the DDL execution, so I've truncated this part of the log here. However, the basic outline can be sorted out. Firstly, the DDL execution is initiated from ddl_api, at this time recording `["CRUCIAL OPERATION"]` style logs. DDL is a crucial operation, so it belongs to CRUCIAL type logs. Then, we can see a series of logs with the ddl keyword linked together, such as `[ddl] add DDL jobs`, `[ddl] start DDL job`, `[ddl] run DDL job`, `[ddl] finish DDL job`, and `[ddl] DDL job is finished`. These represent the process from when the DDL owner acquires a job to its final execution completion. Moreover, they have a unique job ID, which can be used to link a DDL in the log with something like `jobs="ID:2`.

---

[2020/08/12 16:12:07.518 +08:00] [INFO] [server.go:235] ["server is running MySQL protocol"] [addr=0.0.0.0:4000]
[2020/08/12 16:12:07.518 +08:00] [INFO] [http_status.go:80] ["for status and metrics report"] ["listening on addr"=0.0.0.0:10080]
[2020/08/12 16:12:07.520 +08:00] [INFO] [domain.go:1015] ["init stats info time"] ["take time"=3.0126ms]
[2020/08/12 16:15:41.482 +08:00] [INFO] [server.go:388] ["new connection"] [conn=1] [remoteAddr=127.0.0.1:64888]
[2020/08/12 21:03:19.954 +08:00] [INFO] [server.go:391] ["connection closed"] [conn=1]

Thereafter, the appearance of `server is running MySQL protocol` means that TiDB can provide services externally. Later, there are logs corresponding to the creation and closing of each connection, namely `new connection` and `connection closed`. Of course, they also have their corresponding connection ID, which is unique for a TiDB. You can use the keyword `conn=1` in the log to contextually link them together.

### Stack Logs

Most of TiDB's SQL errors (except for duplicate entry and syntax errors) will output the complete stack information. Due to the requirements of unified log format, the stack now looks very unsightly...

```text
For this stack trace, I believe no one really enjoys reading it. Therefore, we need to paste it into Vim and execute `%s/\\n/\r/g` and `%s/\\t/    /g` to turn it into a Golang-style stack.

![func](/posts/images/20200812211203.png)

When you see which module it's stuck in, like the plan part here, you can find the corresponding colleague for support.

However, there is a more user-friendly tool for dealing with Golang’s lengthy stack called [panicparse](https://github.com/maruel/panicparse). To install it, simply run
`go get github.com/maruel/panicparse/v2/cmd/pp`. The effect is as follows:

![func](/posts/images/20200813172149.png)

Whether it's TiDB running goroutines or panic outputs, it can be parsed using this. It has several features:

1. It can display active and inactive goroutines.
2. It can show the relationships between goroutines.
3. Keyword highlighting.
4. Supports Windows.

The latest 2.0.0 version supports race detector and HTML formatted output.

This concludes the introduction to the analysis of key functions and logs (startup, DDL, connection, error stack).
