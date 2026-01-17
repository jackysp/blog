package main

import (
	"log"
	"os"

	"github.com/gohugoio/hugo/commands"
)

func main() {
	if err := commands.Execute(os.Args[1:]); err != nil {
		log.Fatalf("Hugo command failed: %v", err)
	}
}
