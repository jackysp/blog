package main

import (
	"log"
	"os"
	"os/exec"
)

func main() {
	err := exec.Command("go", "get", "github.com/gohugoio/hugo").Run()
	if err != nil {
		log.Println("go get hugo failed error:", err)
		os.Exit(1)
	}
	log.Println("go get hugo successful!")
	err = exec.Command("hugo").Run()
	if err != nil {
		log.Println("hugo run failed error:", err)
		os.Exit(1)
	}
	log.Println("hugo run successful!")
}
