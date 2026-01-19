---
title: "The Correct Way to Use `go build`"
slug: "the-correct-way-to-use-go-build"
tags: ['golang', 'programming']
date: 2024-11-28T15:41:19+08:00
draft: false
---

When working with Go, it's important to know the proper way to compile your programs to avoid common errors. Here are some tips on using the `go build` command effectively.

## Recommended Usage

- **Compile all Go files in the current directory:**

  ```bash
  go build
  ```

- **Compile all Go files explicitly:**

  ```bash
  go build *.go
  ```

## Common Pitfalls

### Compiling a Single File

Running:

```bash
go build main.go
```

will only build `main.go`. This can lead to errors if `main.go` depends on other Go files in the same package, as those files won't be included in the build process.

### Including Non-Go Files

Using:

```bash
go build *
```

will cause an error if the `*` wildcard includes non-Go files. The compiler will output an error message stating that only Go files can be compiled. This serves as a precise reminder to exclude non-Go files from the build command.

---

By using `go build` correctly, you can ensure that all necessary files in your package are compiled together, avoiding missing dependencies and other common compilation issues.
