---
title: How to Implement MySQL X Protocol on TiDB
date: 2017-08-16
---

# Some Documents on MySQL

* Client Usage Guide [MySQL Shell User Guide](https://dev.mysql.com/doc/refman/5.7/en/mysql-shell.html)
* Server Configuration Guide [Using MySQL as a Document Store](https://dev.mysql.com/doc/refman/5.7/en/document-store.html)
* Application Development API Guide [X DevAPI User Guide](https://dev.mysql.com/doc/x-devapi-userguide/en/)
* Introduction to Server Internal Implementation [X Protocol](https://dev.mysql.com/doc/internals/en/x-protocol.html).

# Implementation Principle

* Communication between client and server is over TCP and the protocol uses protobuf.
* After the server receives a message, it decodes and analyzes it. The protocol includes a concept called namespace, which specifically refers to whether the namespace is empty or "sql", in which case the message content is executed as a SQL statement; if it is "xplugin" or "mysqlx," the message is handled in another way. The other ways can be divided into:
  * Administrative commands
  * CRUD operations
* "xplugin" and "mysqlx" have the same function, with the latter being the new name for the former, retained temporarily for compatibility.
* The content of "mysqlx" messages, apart from explicit command content like kill_client, are mostly transformed into SQL statements which the server processes, essentially turning most into a form where the namespace is "sql".

# Implementation Steps

1. Start a new server for TiDB. The relevant configuration parameters such as IP, port, and socket need to be set.
2. Implement the reading and writing functionality for message communication.
3. Write a process for this new server to establish connections, including authentication, that follows the protocol. Use tcpdump to capture messages between MySQL and the client to derive protocol content, implementing the process by understanding MySQL source code.
4. The server should include contents like the Query Context from the original TiDB server, as it primarily translates into SQL for execution.
5. Implement the decoding and handling of messages. Although only a sentence, the workload included is substantial.

<!---
In `mysqlx_all_msgs.h`, all messages are initialized

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

Server and client messages are that many. Client messages are dispatched in `xpl_dispatcher.cc`.

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

The rest is filling in the gaps.

```
Client::run => Client::handle_message => Session::handle_message => Session::handle_auth_message => some auth handlers
                                                                 => Session::handle_ready_message => xpl::dispatcher::dispatch_command => ngs::Error_code do_dispatch_command => some crud handlers
```

Mapping between MySQL type and X protocol type

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

The first SQL field information of MySQL:

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
For TiDB:

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
