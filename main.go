package main

import (
	"log"
	"os/exec"

	"github.com/gohugoio/hugo/commands"
)

func main() {
	commandLine("rm", []string{"-rf", "themes/kiss"})
	commandLine("git", []string{"clone", "https://github.com/ribice/kiss.git", "themes/kiss"})
	commands.Execute([]string{})
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
