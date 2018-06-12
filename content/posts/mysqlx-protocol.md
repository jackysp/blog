---
title:  如何在 TiDB 上实现 MySQL X Protocol"
date: 2017-08-16T22:21:06+08:00
---

# MySQL 的一些文档

* 客户端使用指南 [MySQL Shell User Guide](https://dev.mysql.com/doc/refman/5.7/en/mysql-shell.html)
* 服务端配置指南 [Using MySQL as a Document Store](https://dev.mysql.com/doc/refman/5.7/en/document-store.html)
* 应用开发接口指南 [X DevAPI User Guide](https://dev.mysql.com/doc/x-devapi-userguide/en/)
* 服务端内部实现介绍 [X Protocol](https://dev.mysql.com/doc/internals/en/x-protocol.html).

# 实现原理

* 客户端与服务端之间靠 tcp 通信，协议使用了 protobuf 。
* 服务端接收到消息后，把消息解码后分析。协议中包含了 namespace 这样一个概念，具体是指，如果 namespace 为空或者 "sql" ，则消息内容按照 sql 语句来执行，如果为 "xplugin" 、 "mysqlx" 则消息按照其他方式来处理。其他方式又可分为：
  * 管理命令
  * CRUD 操作
* "xplugin" 和 "mysqlx" 作用完全相同，后者是前者的新名字，为了保持兼容暂时没有去掉前者。
* "mysqlx" 的消息除了个别如 kill_client 这样的明显的命令内容外，都是用拼 sql 的方式，转给服务端进行处理。也就是大部分也变成了 namespace 为 "sql" 的形式。

# 实现步骤

1. 给 TiDB 启动一个新的 server 。需要相关的配置参数， ip 、 port 、 socket 之类的东西。
2. 实现消息通讯的读和写功能。
3. 需要为这个新 server 写一个建立连接的过程，包括认证等内容，过程要遵循协议。为了得到协议内容，可使用 tcpdump 来抓取 MySQL 与客户端的消息内容。再结合对 MySQL 源代码的理解来实现这个过程。
4. server 中要包含原 TiDB server 的 Query Context 等内容，因为主要还是要转成 sql 去执行。
5. 实现对消息的解码处理。虽然只有一句话，但是包含的工作量巨大。

<!---
在`mysqlx_all_msgs.h`里初始化了所有消息

```c++
  init_message_factory()
  {
    server_message<Mysqlx::Connection::Capabilities>(Mysqlx::ServerMessages::CONN_CAPABILITIES, "CONN_CAPABILITIES", "Mysqlx.Connection.Capabilities");
    server_message<Mysqlx::Error>(Mysqlx::ServerMessages::ERROR, "ERROR", "Mysqlx.Error");
    server_message<Mysqlx::Notice::Frame>(Mysqlx::ServerMessages::NOTICE, "NOTICE", "Mysqlx.Notice.Frame");
    server_message<Mysqlx::Ok>(Mysqlx::ServerMessages::OK, "OK", "Mysqlx.Ok");
    server_message<Mysqlx::Resultset::ColumnMetaData>(Mysqlx::ServerMessages::RESULTSET_COLUMN_META_DATA, "RESULTSET_COLUMN_META_DATA", "Mysqlx.Resultset.ColumnMetaData");
    server_message<Mysqlx::Resultset::FetchDone>(Mysqlx::ServerMessages::RESULTSET_FETCH_DONE, "RESULTSET_FETCH_DONE", "Mysqlx.Resultset.FetchDone");
    server_message<Mysqlx::Resultset::FetchDoneMoreResultsets>(Mysqlx::ServerMessages::RESULTSET_FETCH_DONE_MORE_RESULTSETS, "RESULTSET_FETCH_DONE_MORE_RESULTSETS", "Mysqlx.Resultset.FetchDoneMoreResultsets");
    server_message<Mysqlx::Resultset::Row>(Mysqlx::ServerMessages::RESULTSET_ROW, "RESULTSET_ROW", "Mysqlx.Resultset.Row");
    server_message<Mysqlx::Session::AuthenticateOk>(Mysqlx::ServerMessages::SESS_AUTHENTICATE_OK, "SESS_AUTHENTICATE_OK", "Mysqlx.Session.AuthenticateOk");
    server_message<Mysqlx::Sql::StmtExecuteOk>(Mysqlx::ServerMessages::SQL_STMT_EXECUTE_OK, "SQL_STMT_EXECUTE_OK", "Mysqlx.Sql.StmtExecuteOk");

    client_message<Mysqlx::Connection::CapabilitiesGet>(Mysqlx::ClientMessages::CON_CAPABILITIES_GET, "CON_CAPABILITIES_GET", "Mysqlx.Connection.CapabilitiesGet");
    client_message<Mysqlx::Connection::CapabilitiesSet>(Mysqlx::ClientMessages::CON_CAPABILITIES_SET, "CON_CAPABILITIES_SET", "Mysqlx.Connection.CapabilitiesSet");
    client_message<Mysqlx::Connection::Close>(Mysqlx::ClientMessages::CON_CLOSE, "CON_CLOSE", "Mysqlx.Connection.Close");
    client_message<Mysqlx::Crud::Delete>(Mysqlx::ClientMessages::CRUD_DELETE, "CRUD_DELETE", "Mysqlx.Crud.Delete");
    client_message<Mysqlx::Crud::Find>(Mysqlx::ClientMessages::CRUD_FIND, "CRUD_FIND", "Mysqlx.Crud.Find");
    client_message<Mysqlx::Crud::Insert>(Mysqlx::ClientMessages::CRUD_INSERT, "CRUD_INSERT", "Mysqlx.Crud.Insert");
    client_message<Mysqlx::Crud::Update>(Mysqlx::ClientMessages::CRUD_UPDATE, "CRUD_UPDATE", "Mysqlx.Crud.Update");
    client_message<Mysqlx::Crud::CreateView>(Mysqlx::ClientMessages::CRUD_CREATE_VIEW, "CRUD_CREATE_VIEW", "Mysqlx.Crud.CreateView");
    client_message<Mysqlx::Crud::ModifyView>(Mysqlx::ClientMessages::CRUD_MODIFY_VIEW, "CRUD_MODIFY_VIEW", "Mysqlx.Crud.ModifyView");
    client_message<Mysqlx::Crud::DropView>(Mysqlx::ClientMessages::CRUD_DROP_VIEW, "CRUD_DROP_VIEW", "Mysqlx.Crud.DropView");
    client_message<Mysqlx::Expect::Close>(Mysqlx::ClientMessages::EXPECT_CLOSE, "EXPECT_CLOSE", "Mysqlx.Expect.Close");
    client_message<Mysqlx::Expect::Open>(Mysqlx::ClientMessages::EXPECT_OPEN, "EXPECT_OPEN", "Mysqlx.Expect.Open");
    client_message<Mysqlx::Session::AuthenticateContinue>(Mysqlx::ClientMessages::SESS_AUTHENTICATE_CONTINUE, "SESS_AUTHENTICATE_CONTINUE", "Mysqlx.Session.AuthenticateContinue");
    client_message<Mysqlx::Session::AuthenticateStart>(Mysqlx::ClientMessages::SESS_AUTHENTICATE_START, "SESS_AUTHENTICATE_START", "Mysqlx.Session.AuthenticateStart");
    client_message<Mysqlx::Session::Close>(Mysqlx::ClientMessages::SESS_CLOSE, "SESS_CLOSE", "Mysqlx.Session.Close");
    client_message<Mysqlx::Session::Reset>(Mysqlx::ClientMessages::SESS_RESET, "SESS_RESET", "Mysqlx.Session.Reset");
    client_message<Mysqlx::Sql::StmtExecute>(Mysqlx::ClientMessages::SQL_STMT_EXECUTE, "SQL_STMT_EXECUTE", "Mysqlx.Sql.StmtExecute");
  }
```

server 和 client 的消息就这么多。对于client的消息，在`xpl_dispatcher.cc`里dispatch。

```c++
ngs::Error_code do_dispatch_command(xpl::Session &session, xpl::Crud_command_handler &crudh,
                                    xpl::Expectation_stack &expect, ngs::Request &command)
{
  switch (command.get_type())
  {
    case Mysqlx::ClientMessages::SQL_STMT_EXECUTE:
      return on_stmt_execute(session, static_cast<const Mysqlx::Sql::StmtExecute&>(*command.message()));

    case Mysqlx::ClientMessages::CRUD_FIND:
      return crudh.execute_crud_find(session, static_cast<const Mysqlx::Crud::Find&>(*command.message()));

    case Mysqlx::ClientMessages::CRUD_INSERT:
      return crudh.execute_crud_insert(session, static_cast<const Mysqlx::Crud::Insert&>(*command.message()));

    case Mysqlx::ClientMessages::CRUD_UPDATE:
      return crudh.execute_crud_update(session, static_cast<const Mysqlx::Crud::Update&>(*command.message()));

    case Mysqlx::ClientMessages::CRUD_DELETE:
      return crudh.execute_crud_delete(session, static_cast<const Mysqlx::Crud::Delete&>(*command.message()));

    case Mysqlx::ClientMessages::CRUD_CREATE_VIEW:
      return crudh.execute_create_view(session, static_cast<const Mysqlx::Crud::CreateView&>(*command.message()));

    case Mysqlx::ClientMessages::CRUD_MODIFY_VIEW:
      return crudh.execute_modify_view(session, static_cast<const Mysqlx::Crud::ModifyView&>(*command.message()));

    case Mysqlx::ClientMessages::CRUD_DROP_VIEW:
      return crudh.execute_drop_view(session, static_cast<const Mysqlx::Crud::DropView&>(*command.message()));

    case Mysqlx::ClientMessages::EXPECT_OPEN:
      return on_expect_open(session, expect, static_cast<const Mysqlx::Expect::Open&>(*command.message()));

    case Mysqlx::ClientMessages::EXPECT_CLOSE:
      return on_expect_close(session, expect, static_cast<const Mysqlx::Expect::Close&>(*command.message()));
  }

  session.proto().get_protocol_monitor().on_error_unknown_msg_type();
  return ngs::Error(ER_UNKNOWN_COM_ERROR, "Unexpected message received");
}
```

剩下就是填空了吧。

```
Client::run => Client::handle_message => Session::handle_message => Session::handle_auth_message => some auth handlers
                                                                 => Session::handle_ready_message => xpl::dispatcher::dispatch_command => ngs::Error_code do_dispatch_command => some crud handlers
```

MySQL type 与 X protocol type 的对应关系

```
//     ================= ============ ======= ========== ====== ========
//     SQL Type          .type        .length .frac_dig  .flags .charset
//     ================= ============ ======= ========== ====== ========
//     TINY              SINT         x
//     TINY UNSIGNED     UINT         x                  x
//     SHORT             SINT         x
//     SHORT UNSIGNED    UINT         x                  x
//     INT24             SINT         x
//     INT24 UNSIGNED    UINT         x                  x
//     INT               SINT         x
//     INT UNSIGNED      UINT         x                  x
//     LONGLONG          SINT         x
//     LONGLONG UNSIGNED UINT         x                  x
//     DOUBLE            DOUBLE       x       x          x
//     FLOAT             FLOAT        x       x          x
//     DECIMAL           DECIMAL      x       x          x
//     VARCHAR,CHAR,...  BYTES        x                  x      x
//     GEOMETRY          BYTES
//     TIME              TIME         x
//     DATE              DATETIME     x
//     DATETIME          DATETIME     x
//     YEAR              UINT         x                  x
//     TIMESTAMP         DATETIME     x
//     SET               SET                                    x
//     ENUM              ENUM                                   x
//     NULL              BYTES
//     BIT               BIT          x
//     ================= ============ ======= ========== ====== ========
```

mysql的第一个sql的字段信息：

```
Field   1:  `@@lower_case_table_names`
Catalog:    `def`
Database:   ``
Table:      ``
Org_table:  ``
Type:       LONGLONG
Collation:  binary (63)
Length:     21
Max_length: 1
Decimals:   0
Flags:      UNSIGNED BINARY NUM 

Field   2:  `connection_id()`
Catalog:    `def`
Database:   ``
Table:      ``
Org_table:  ``
Type:       LONGLONG
Collation:  binary (63)
Length:     21
Max_length: 1
Decimals:   0
Flags:      NOT_NULL UNSIGNED BINARY NUM 

Field   3:  `variable_value`
Catalog:    `def`
Database:   `performance_schema`
Table:      `session_status`
Org_table:  `session_status`
Type:       VAR_STRING
Collation:  utf8_general_ci (33)
Length:     3072
Max_length: 0
Decimals:   0
Flags:      
```
tidb的：

```
Field   1:  `@@lower_case_table_names`
Catalog:    `def`
Database:   ``
Table:      ``
Org_table:  ``
Type:       STRING
Collation:  ? (0)
Length:     0
Max_length: 1
Decimals:   31
Flags:      

Field   2:  `connection_id()`
Catalog:    `def`
Database:   ``
Table:      ``
Org_table:  ``
Type:       LONGLONG
Collation:  binary (63)
Length:     20
Max_length: 1
Decimals:   0
Flags:      UNSIGNED BINARY NUM 

Field   3:  `variable_value`
Catalog:    `def`
Database:   ``
Table:      ``
Org_table:  ``
Type:       STRING
Collation:  utf8_general_ci (33)
Length:     1024
Max_length: 0
Decimals:   0
Flags:      
```
-->