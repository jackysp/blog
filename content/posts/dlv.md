---
title: "Using delve to Debug Golang Programs"
date: 2019-09-16T13:24:00+08:00
---

## Background

When I first started writing Golang, I was always looking for a convenient debugging tool. Back then, I came across documentation about using `gdb` to debug and also tried `delve`, but neither felt easy to use. Later, on someone's advice, I went back to the good old `print` statements...

Over the past couple of days, I was debugging `go test` and found that tests would always hang when run per package. I couldn't think of a suitable method at first, so I thought of `delve` again. After giving it a try, I found it has become much more mature than before.

## Usage

`dlv attach ${pid}` is the method I use most often. After attaching, you can use debugging commands similar to `gdb`. You can use `help` to view specific commands.

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
    goroutine (alias: gr) ------- Shows or changes current goroutine.
    goroutines (alias: grs) ----- List program goroutines.
    help (alias: h) ------------- Prints the help message.
    libraries ------------------- List loaded dynamic libraries.
    list (alias: ls | l) -------- Show source code.
    locals ---------------------- Print local variables.
    next (alias: n) ------------- Step over to next source line.
    on -------------------------- Executes a command when a breakpoint is hit.
    print (alias: p) ------------ Evaluate an expression.
    regs ------------------------ Print contents of CPU registers.
    restart (alias: r) ---------- Restart process.
    set ------------------------- Changes the value of a variable.
    source ---------------------- Executes a file containing a list of delve commands.
    sources --------------------- Print list of source files.
    stack (alias: bt) ----------- Print stack trace.
    step (alias: s) ------------- Single step through program.
    step-instruction (alias: si)  Single step a single CPU instruction.
    stepout (alias: so) --------- Step out of the current function.
    thread (alias: tr) ---------- Switch to the specified thread.
    threads --------------------- Print out info for every traced thread.
    trace (alias: t) ------------ Set tracepoint.
    types ----------------------- Print list of types.
    up -------------------------- Move the current frame up.
    vars ------------------------ Print package variables.
    whatis ---------------------- Prints type of an expression.
Type help followed by a command for full documentation.
```

Many of these commands are the same as those in `gdb`. Another command I use frequently is `grs`, which outputs all goroutines. You can also use `grs -t`, which is equivalent to `gdb`'s `t a a bt`. The only slight drawback is that it only outputs 10 stack frames, and any additional ones are truncated.

Additionally, it seems that processes forked by `go test` can't be attached to. If you want to test, you must first compile it into a test file and then execute it. You can refer to [this issue](https://github.com/pingcap/tidb/issues/12184) for more details.

```text
$ dlv attach 19654
could not attach to pid 19654: decoding dwarf section info at offset 0x0: too short
```

Furthermore, by default, Go's `test` caches results, which can be controlled via environment variables. However, with Go modules (`go mod`), it's recommended to use `./ddl.test -test.count=1` to disable caching. It doesn't feel very elegant.
