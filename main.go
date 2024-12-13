package main

import (
	"io"
	"log"
	"os"
	"os/exec"

	"github.com/gohugoio/hugo/commands"
)

func main() {
	os.RemoveAll("themes/PaperMod")
	commandLine("git", []string{"clone", "https://github.com/adityatelange/hugo-PaperMod", "themes/PaperMod", "--depth=1"})
	copyFile("comments.html", "themes/PaperMod/layouts/partials/comments.html")
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

func copyFile(src, dst string) {
	sourceFile, err := os.Open(src)
	if err != nil {
		log.Fatal(err)
	}
	defer sourceFile.Close()

	destinationFile, err := os.Create(dst)
	if err != nil {
		log.Fatal(err)
	}
	defer destinationFile.Close()

	_, err = io.Copy(destinationFile, sourceFile)
	if err != nil {
		log.Fatal(err)
	}
}
