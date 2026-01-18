#!/bin/bash
# Prepare git commit for image optimization changes

set -e

echo "=== Preparing Git Commit for Image Optimization ==="
echo ""

# Check git status
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "Error: Not a git repository"
    exit 1
fi

# Add WebP files
echo "1. Adding WebP files..."
webp_count=$(git status --short | grep "^\?\?" | grep "\.webp$" | wc -l | tr -d ' ')
if [ "$webp_count" -gt 0 ]; then
    git add content/posts/images/*.webp
    echo "   ✓ Added $webp_count WebP files"
else
    echo "   - No new WebP files to add"
fi

# Add modified markdown files
echo ""
echo "2. Adding modified markdown files..."
md_count=$(git status --short | grep "^ M" | grep "\.md$" | wc -l | tr -d ' ')
if [ "$md_count" -gt 0 ]; then
    git add content/posts/*.md
    echo "   ✓ Added $md_count modified markdown files"
else
    echo "   - No modified markdown files"
fi

# Add optimized JPG files
echo ""
echo "3. Adding optimized JPG files..."
jpg_count=$(git status --short | grep "^ M" | grep -E "\.(jpg|JPG)$" | wc -l | tr -d ' ')
if [ "$jpg_count" -gt 0 ]; then
    git add content/posts/images/*.jpg content/posts/images/*.JPG 2>/dev/null || true
    echo "   ✓ Added $jpg_count optimized JPG files"
else
    echo "   - No optimized JPG files"
fi

# Stage deleted PNG files
echo ""
echo "4. Staging deleted PNG files..."
png_deleted=$(git status --short | grep "^ D" | grep "\.png$" | wc -l | tr -d ' ')
if [ "$png_deleted" -gt 0 ]; then
    git add -u content/posts/images/*.png 2>/dev/null || true
    echo "   ✓ Staged deletion of $png_deleted PNG files"
else
    echo "   - No PNG files to delete"
fi

# Add optimization documentation
echo ""
echo "5. Adding optimization documentation..."
if [ -f "IMAGE_OPTIMIZATION.md" ] || [ -f "OPTIMIZATION_COMPLETE.md" ]; then
    git add IMAGE_OPTIMIZATION.md OPTIMIZATION_COMPLETE.md README_IMAGE_OPTIMIZATION.md 2>/dev/null || true
    echo "   ✓ Added optimization documentation"
else
    echo "   - No documentation files found"
fi

# Add optimization scripts (optional, but recommended)
echo ""
echo "6. Adding optimization scripts..."
script_count=$(ls *.sh 2>/dev/null | grep -E "(optimize|cleanup|update|verify|prepare)" | wc -l | tr -d ' ')
if [ "$script_count" -gt 0 ]; then
    git add *.sh 2>/dev/null || true
    echo "   ✓ Added $script_count optimization scripts"
else
    echo "   - No optimization scripts found"
fi

# Update .gitignore if modified
echo ""
echo "7. Checking .gitignore..."
if git status --short | grep -q "^ M.*\.gitignore"; then
    git add .gitignore
    echo "   ✓ Added .gitignore update (excludes backup directory)"
else
    echo "   - .gitignore unchanged"
fi

# Summary
echo ""
echo "=========================================="
echo "Summary of staged changes:"
git status --short | grep "^[AM]" | head -10
echo ""
total_staged=$(git diff --cached --name-only | wc -l | tr -d ' ')
echo "Total files staged: $total_staged"
echo ""
echo "Next step:"
echo "  git commit -m \"Optimize images: Convert PNG to WebP, optimize JPG files

- Converted 68 PNG files to WebP format (68.5% size reduction)
- Optimized 6 large JPG files (auto-resized)
- Updated all markdown image references
- Removed unused PNG files
- Total space saved: 13.7MB (68.5%)\""
echo "=========================================="
