package main

import (
	"log"
	"os"
	"os/exec"

	"github.com/gohugoio/hugo/commands"
)

func main() {
	os.RemoveAll("themes/hyde")
	commandLine("git", []string{"clone", "https://github.com/spf13/hyde.git", "themes/hyde", "--depth", "1"})
	err := commands.Execute(os.Args[1:])
	if err != nil {
		log.Fatal(err)
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
