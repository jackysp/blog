package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"

	"github.com/gohugoio/hugo/commands"
)

const (
	commentsFile = "comments.html"
	commentsDst  = "themes/PaperMod/layouts/partials/comments.html"
)

func main() {
	if err := copyCommentsFile(); err != nil {
		log.Fatalf("Failed to copy comments file: %v", err)
	}

	if err := commands.Execute(os.Args[1:]); err != nil {
		log.Fatalf("Hugo command failed: %v", err)
	}
}

func copyCommentsFile() error {
	// Ensure destination directory exists
	destDir := filepath.Dir(commentsDst)
	if err := os.MkdirAll(destDir, 0755); err != nil {
		return fmt.Errorf("failed to create destination directory: %w", err)
	}

	sourceFile, err := os.Open(commentsFile)
	if err != nil {
		return fmt.Errorf("failed to open source file: %w", err)
	}
	defer sourceFile.Close()

	destinationFile, err := os.Create(commentsDst)
	if err != nil {
		return fmt.Errorf("failed to create destination file: %w", err)
	}
	defer destinationFile.Close()

	if _, err := io.Copy(destinationFile, sourceFile); err != nil {
		return fmt.Errorf("failed to copy file: %w", err)
	}

	log.Printf("Copied %s to %s", commentsFile, commentsDst)
	return nil
}
