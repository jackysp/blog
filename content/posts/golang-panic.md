---
title: "Golang panic 的实时性是怎样的"
date: 2018-07-26T14:24:00+08:00
draft: false
---

先看下面这段代码，

```golang
package main

import (
	"fmt"
	"os"
	"runtime"
	"time"
)

func main() {
	runtime.GOMAXPROCS(2)
	a := make(map[int]int)
	go func() {
		i := 0
		for {
			a[1] = i
			i++
			time.Sleep(1000)
		}
	}()
	for {
		if a[1] > 1000000 {
			fmt.Println(a[1])
			os.Exit(1)
		}
	}
}
```

编译完之后，运行，会得到下面的错误（前提你的机器有 2 个及以上的核），

```text
fatal error: concurrent map read and map write

goroutine 1 [running]:
runtime.throw(0x10c3e05, 0x21)
        /usr/local/Cellar/go/1.10.3/libexec/src/runtime/panic.go:616 +0x81 fp=0xc42004bf00 sp=0xc42004bee0 pc=0x10263f1
runtime.mapaccess1_fast64(0x10a5b60, 0xc42007e180, 0x1, 0xc42008e048)
        /usr/local/Cellar/go/1.10.3/libexec/src/runtime/hashmap_fast.go:101 +0x197 fp=0xc42004bf28 sp=0xc42004bf00 pc=0x1008d27
main.main()
        /Users/yusp/test/panic3/main.go:22 +0x7c fp=0xc42004bf88 sp=0xc42004bf28 pc=0x108e28c
runtime.main()
        /usr/local/Cellar/go/1.10.3/libexec/src/runtime/proc.go:198 +0x212 fp=0xc42004bfe0 sp=0xc42004bf88 pc=0x1027c62
runtime.goexit()
        /usr/local/Cellar/go/1.10.3/libexec/src/runtime/asm_amd64.s:2361 +0x1 fp=0xc42004bfe8 sp=0xc42004bfe0 pc=0x104e501

goroutine 5 [runnable]:
time.Sleep(0x3e8)
        /usr/local/Cellar/go/1.10.3/libexec/src/runtime/time.go:102 +0x166
main.main.func1(0xc42007e180)
        /Users/yusp/test/panic3/main.go:18 +0x61
created by main.main
        /Users/yusp/test/panic3/main.go:13 +0x59
```

看起来没什么问题，golang 的 map 不是线程安全的，同时读写会造成 panic。但是看下 `/Users/yusp/test/panic3/main.go:18 +0x61` 这行错误信息，main.go 的 18 行是 Sleep，也就是并不是并发问题的现场。在一个庞大的栈信息里，就更不可能定位到出问题的地方了。

解决方法目前想到的是，如果是只看到了读的栈，想看写的，那么在读的位置设置变量，读完后复原该变量，在写的位置检测该变量的值，如果正在读，就 panic 出来。