package main

import (
	"log"

	"github.com/gohugoio/hugo/commands"
)

func main() {
	resp := commands.Execute([]string{})
	if resp.Err != nil {
		log.Fatal(resp.Err)
	}
}
