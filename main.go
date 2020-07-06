package main

import (
	"log"
	"os"
	"os/exec"

	"github.com/gohugoio/hugo/commands"
)

func main() {
	os.RemoveAll("themes/hyde")
	commandLine("git", []string{"clone", "https://github.com/spf13/hyde.git", "themes/hyde"})
	resp := commands.Execute(os.Args[1:])
	if resp.Err != nil {
		log.Fatal(resp.Err)
	}
}

func commandLine(name string, args []string) {
	log.Println(name, args)
	out, err := exec.Command(name, args...).Output()
	if err != nil {
		if len(out) != 0 {
			log.Print(string(out))
		}
		log.Fatal(err)
	}
	if len(out) != 0 {
		log.Print(string(out))
	}
}
