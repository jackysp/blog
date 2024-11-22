Here is the translation of the given text into English:

---

title: "How Immediate is Golang's Panic"

date: 2018-07-26T14:24:00+08:00

draft: false

---

Let's first look at the following code snippet:

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

After compiling and running it (assuming your machine has 2 or more cores), you will get the following error:

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

It seems straightforward; Golang's map is not thread-safe, and concurrent read and write cause a panic. However, look at the error information on line `/Users/yusp/test/panic3/main.go:18 +0x61`, which points to line 18 of main.go where `Sleep` is called, not the actual point of concurrency issue. In a vast stack trace, it becomes even harder to locate the problem.

A workaround that comes to mind is if you only see the read stack and want to see the write stack, set a variable at the read position, reset it after reading, and check the value of this variable at the write position. If reading is currently happening, panic will be triggered.