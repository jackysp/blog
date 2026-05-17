package main

import (
	"bytes"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"slices"
	"strings"
)

const (
	postsDir     = "content/posts"
	maxImageSize = 1 << 20
)

var (
	markdownImagePattern = regexp.MustCompile(`!\[[^\]]*]\(([^)\s]+)(?:\s+"[^"]*")?\)`)
	slugPattern          = regexp.MustCompile(`^[a-z0-9-]+$`)
	imageExts            = map[string]bool{
		".gif": true, ".jpeg": true, ".jpg": true, ".png": true, ".svg": true, ".webp": true,
	}
)

func main() {
	var failures []string
	var warnings []string

	usedImages, postFailures := checkPosts()
	failures = append(failures, postFailures...)

	imageFailures, imageWarnings := checkImages(usedImages)
	failures = append(failures, imageFailures...)
	warnings = append(warnings, imageWarnings...)

	for _, warning := range warnings {
		fmt.Fprintf(os.Stderr, "warning: %s\n", warning)
	}
	if len(failures) > 0 {
		for _, failure := range failures {
			fmt.Fprintf(os.Stderr, "error: %s\n", failure)
		}
		os.Exit(1)
	}
}

func checkPosts() (map[string]bool, []string) {
	usedImages := make(map[string]bool)
	var failures []string

	posts, err := filepath.Glob(filepath.Join(postsDir, "*", "index.md"))
	if err != nil {
		return usedImages, []string{err.Error()}
	}
	slices.Sort(posts)

	for _, post := range posts {
		content, err := os.ReadFile(post)
		if err != nil {
			failures = append(failures, fmt.Sprintf("%s: %v", post, err))
			continue
		}

		frontMatter, ok := parseFrontMatter(string(content))
		if !ok {
			failures = append(failures, fmt.Sprintf("%s: missing YAML front matter", post))
		} else {
			failures = append(failures, validateFrontMatter(post, frontMatter)...)
		}

		bundleDir := filepath.Dir(post)
		for _, match := range markdownImagePattern.FindAllStringSubmatch(string(content), -1) {
			ref := match[1]
			if isExternalRef(ref) {
				continue
			}
			if strings.HasPrefix(ref, "/") {
				failures = append(failures, fmt.Sprintf("%s: image reference %q must be relative to the post bundle", post, ref))
				continue
			}
			cleanRef := filepath.Clean(ref)
			if strings.HasPrefix(cleanRef, "..") || filepath.IsAbs(cleanRef) {
				failures = append(failures, fmt.Sprintf("%s: image reference %q must stay inside the post bundle", post, ref))
				continue
			}
			imagePath := filepath.Join(bundleDir, cleanRef)
			usedImages[imagePath] = true
			if _, err := os.Stat(imagePath); err != nil {
				failures = append(failures, fmt.Sprintf("%s: missing image %q", post, ref))
			}
		}
	}

	return usedImages, failures
}

func parseFrontMatter(content string) (string, bool) {
	if !strings.HasPrefix(content, "---\n") {
		return "", false
	}
	rest := strings.TrimPrefix(content, "---\n")
	end := strings.Index(rest, "\n---")
	if end < 0 {
		return "", false
	}
	return rest[:end], true
}

func validateFrontMatter(post string, frontMatter string) []string {
	var failures []string
	required := []string{"title", "date", "draft", "tags", "slug"}
	for _, key := range required {
		if !hasFrontMatterKey(frontMatter, key) {
			failures = append(failures, fmt.Sprintf("%s: missing front matter field %q", post, key))
		}
	}

	slug, ok := frontMatterValue(frontMatter, "slug")
	if !ok {
		return failures
	}
	base := filepath.Base(filepath.Dir(post))
	if slug != base {
		failures = append(failures, fmt.Sprintf("%s: slug %q does not match bundle directory %q", post, slug, base))
	}
	if !slugPattern.MatchString(slug) {
		failures = append(failures, fmt.Sprintf("%s: slug %q must use lowercase letters, numbers, and hyphens only", post, slug))
	}

	return failures
}

func hasFrontMatterKey(frontMatter string, key string) bool {
	_, ok := frontMatterValue(frontMatter, key)
	return ok
}

func frontMatterValue(frontMatter string, key string) (string, bool) {
	prefix := key + ":"
	for _, line := range strings.Split(frontMatter, "\n") {
		line = strings.TrimSpace(line)
		if !strings.HasPrefix(line, prefix) {
			continue
		}
		value := strings.TrimSpace(strings.TrimPrefix(line, prefix))
		value = strings.Trim(value, `"'`)
		return value, true
	}
	return "", false
}

func isExternalRef(ref string) bool {
	ref = strings.ToLower(ref)
	return strings.HasPrefix(ref, "http://") ||
		strings.HasPrefix(ref, "https://") ||
		strings.HasPrefix(ref, "data:") ||
		strings.HasPrefix(ref, "mailto:") ||
		strings.HasPrefix(ref, "#")
}

func checkImages(usedImages map[string]bool) ([]string, []string) {
	var failures []string
	var warnings []string

	err := filepath.WalkDir(postsDir, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			failures = append(failures, fmt.Sprintf("%s: %v", path, err))
			return nil
		}
		if entry.IsDir() {
			return nil
		}

		ext := strings.ToLower(filepath.Ext(path))
		if !imageExts[ext] {
			return nil
		}
		if !usedImages[path] {
			failures = append(failures, fmt.Sprintf("%s: image is not referenced by any post", path))
		}

		info, err := entry.Info()
		if err != nil {
			failures = append(failures, fmt.Sprintf("%s: %v", path, err))
			return nil
		}
		if info.Size() > maxImageSize {
			failures = append(failures, fmt.Sprintf("%s: image size %d bytes exceeds %d bytes", path, info.Size(), maxImageSize))
		}
		if ext == ".jpg" || ext == ".jpeg" {
			if hasEXIF(path) {
				warnings = append(warnings, fmt.Sprintf("%s contains EXIF metadata; strip it before publishing privacy-sensitive photos", path))
			}
		}

		return nil
	})
	if err != nil {
		failures = append(failures, err.Error())
	}

	return failures, warnings
}

func hasEXIF(path string) bool {
	content, err := os.ReadFile(path)
	if err != nil {
		return false
	}
	return bytes.Contains(content, []byte("Exif\x00\x00"))
}
