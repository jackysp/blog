package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"path/filepath"

	"github.com/gohugoio/hugo/commands"
)

const (
	themeDir     = "themes/PaperMod"
	themeRepo    = "https://github.com/jackysp/hugo-PaperMod"
	commentsFile = "comments.html"
	commentsDst  = "themes/PaperMod/layouts/partials/comments.html"
)

func main() {
	if err := ensureTheme(); err != nil {
		log.Fatalf("Failed to ensure theme: %v", err)
	}

	if err := copyCommentsFile(); err != nil {
		log.Fatalf("Failed to copy comments file: %v", err)
	}

	if err := commands.Execute(os.Args[1:]); err != nil {
		log.Fatalf("Hugo command failed: %v", err)
	}
}

func ensureTheme() error {
	// Check if theme directory exists
	if _, err := os.Stat(themeDir); err == nil {
		log.Printf("Theme already exists at %s, skipping clone", themeDir)
		return nil
	}

	// Remove existing directory if it exists but is incomplete
	if err := os.RemoveAll(themeDir); err != nil {
		return fmt.Errorf("failed to remove existing theme directory: %w", err)
	}

	// Clone the theme
	log.Printf("Cloning theme from %s...", themeRepo)
	if err := runGitCommand("clone", themeRepo, themeDir, "--depth=1"); err != nil {
		return fmt.Errorf("failed to clone theme: %w", err)
	}

	log.Printf("Theme cloned successfully")
	return nil
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

func runGitCommand(args ...string) error {
	log.Printf("Running: git %v", args)
	cmd := exec.Command("git", args...)
	output, err := cmd.CombinedOutput()
	if err != nil {
		if len(output) > 0 {
			log.Printf("Git output: %s", string(output))
		}
		return fmt.Errorf("git command failed: %w", err)
	}
	if len(output) > 0 {
		log.Printf("Git output: %s", string(output))
	}
	return nil
}
