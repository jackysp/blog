---
title: "使用 delve 调试 Golang 程序"
date: 2019-09-16T13:24:00+08:00
---

# 背景

一开始写 Golang 的时候，就一直想找一个方便的 debug 工具，当时看到过用 gdb 来 debug 的文档，也用过 delve。但是都觉得不好用。后来，经人指点，又用回了 print 大法。。。

这两天调试 go test，test 按 package 来跑的时候总会 hang 住，一时没想到合适的方法，就又想起 delve 来。试用了一下，比原来成熟了很多。

# 用法

`dlv attach ${pid}` 是我最常用的用法，attach 上之后就可以用类似 gdb 的调试方法，可以用 help 来查看具体命令。

```text
(dlv) help
The following commands are available:
    args ------------------------ Print function arguments.
    break (alias: b) ------------ Sets a breakpoint.
    breakpoints (alias: bp) ----- Print out info for active breakpoints.
    call ------------------------ Resumes process, injecting a function call (EXPERIMENTAL!!!)
    clear ----------------------- Deletes breakpoint.
    clearall -------------------- Deletes multiple breakpoints.
    condition (alias: cond) ----- Set breakpoint condition.
    config ---------------------- Changes configuration parameters.
    continue (alias: c) --------- Run until breakpoint or program termination.
    deferred -------------------- Executes command in the context of a deferred call.
    disassemble (alias: disass) - Disassembler.
    down ------------------------ Move the current frame down.
    edit (alias: ed) ------------ Open where you are in $DELVE_EDITOR or $EDITOR
    exit (alias: quit | q) ------ Exit the debugger.
    frame ----------------------- Set the current frame, or execute command on a different frame.
    funcs ----------------------- Print list of functions.
    goroutine (alias: gr) ------- Shows or changes current goroutine
    goroutines (alias: grs) ----- List program goroutines.
    help (alias: h) ------------- Prints the help message.
    libraries ------------------- List loaded dynamic libraries
    list (alias: ls | l) -------- Show source code.
    locals ---------------------- Print local variables.
    next (alias: n) ------------- Step over to next source line.
    on -------------------------- Executes a command when a breakpoint is hit.
    print (alias: p) ------------ Evaluate an expression.
    regs ------------------------ Print contents of CPU registers.
    restart (alias: r) ---------- Restart process.
    set ------------------------- Changes the value of a variable.
    source ---------------------- Executes a file containing a list of delve commands
    sources --------------------- Print list of source files.
    stack (alias: bt) ----------- Print stack trace.
    step (alias: s) ------------- Single step through program.
    step-instruction (alias: si)  Single step a single cpu instruction.
    stepout (alias: so) --------- Step out of the current function.
    thread (alias: tr) ---------- Switch to the specified thread.
    threads --------------------- Print out info for every traced thread.
    trace (alias: t) ------------ Set tracepoint.
    types ----------------------- Print list of types
    up -------------------------- Move the current frame up.
    vars ------------------------ Print package variables.
    whatis ---------------------- Prints type of an expression.
Type help followed by a command for full documentation.
```

其中有很多与 gdb 相同的命令。其他用的比较多的就是 `grs`，输出所有 goroutine，还可以 `grs -t`，相当于 gdb 的 `t a a bt`。唯一美中不足的是，只能输出 10 条栈信息，多了 truncated 了。
再就是，似乎 go test fork 出来的进程是用不了的，如果想测试，必须先编译成 test 文件，再执行它。具体可以看 https://github.com/pingcap/tidb/issues/12184 。

```text
$ dlv attach 19654
could not attach to pid 19654: decoding dwarf section info at offset 0x0: too short
```

再就是，在使用中，go 的 test 是默认 cache 的，可以通过环境变量控制。但是，有了 go mod 之后，推荐使用 `./ddl.test -test.count=1` 的方式来去掉 cache。感觉很不值观。
