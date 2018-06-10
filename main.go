package main

import (
	"os"
	"os/exec"
)

func main() {
	err := exec.Command("go", "get", "github.com/gohugoio/hugo").Run()
	if err != nil {
		os.Exit(1)
	}
	err = exec.Command("hugo").Run()
	if err != nil {
		os.Exit(1)
	}
}
