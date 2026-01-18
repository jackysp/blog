#!/bin/bash
# Verification script for image optimization

set -e

IMAGES_DIR="content/posts/images"
POSTS_DIR="content/posts"
ERRORS=0

echo "=== Image Optimization Verification ==="
echo ""

# Check 1: Verify WebP files exist
echo "1. Checking WebP files..."
webp_count=$(find "$IMAGES_DIR" -name "*.webp" | wc -l | tr -d ' ')
if [ "$webp_count" -gt 0 ]; then
    echo "   ✓ Found $webp_count WebP files"
else
    echo "   ✗ No WebP files found"
    ERRORS=$((ERRORS + 1))
fi

# Check 2: Verify no PNG references in markdown
echo ""
echo "2. Checking markdown files for PNG references..."
png_refs=$(grep -r "\.png" "$POSTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$png_refs" -eq 0 ]; then
    echo "   ✓ No PNG references found in markdown files"
else
    echo "   ✗ Found $png_refs PNG references (should be 0)"
    grep -r "\.png" "$POSTS_DIR"/*.md 2>/dev/null | head -5
    ERRORS=$((ERRORS + 1))
fi

# Check 3: Verify WebP references exist
echo ""
echo "3. Checking for WebP references in markdown..."
webp_refs=$(grep -r "\.webp" "$POSTS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$webp_refs" -gt 0 ]; then
    echo "   ✓ Found $webp_refs WebP references in markdown files"
else
    echo "   ⚠ No WebP references found (may be normal if no images were converted)"
fi

# Check 4: Verify image file sizes
echo ""
echo "4. Checking image file sizes..."
large_files=$(find "$IMAGES_DIR" -type f \( -name "*.jpg" -o -name "*.JPG" -o -name "*.png" -o -name "*.webp" \) -size +2M | wc -l | tr -d ' ')
if [ "$large_files" -eq 0 ]; then
    echo "   ✓ No images larger than 2MB"
else
    echo "   ⚠ Found $large_files images larger than 2MB:"
    find "$IMAGES_DIR" -type f \( -name "*.jpg" -o -name "*.JPG" -o -name "*.png" -o -name "*.webp" \) -size +2M -exec ls -lh {} \; | awk '{print "     " $9 " (" $5 ")"}'
fi

# Check 5: Verify backup directory
echo ""
echo "5. Checking backup directory..."
if [ -d "content/posts/images-backup" ]; then
    backup_size=$(du -sh content/posts/images-backup 2>/dev/null | cut -f1)
    backup_count=$(find content/posts/images-backup -type f | wc -l | tr -d ' ')
    echo "   ✓ Backup directory exists ($backup_count files, $backup_size)"
    echo "     Location: content/posts/images-backup"
else
    echo "   ⚠ Backup directory not found (may have been removed)"
fi

# Summary
echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo "✓ Verification passed!"
    echo ""
    echo "Next steps:"
    echo "  1. Test your blog locally to ensure images display correctly"
    echo "  2. Review the changes: git status"
    echo "  3. After verification, you can remove backup: rm -rf content/posts/images-backup"
else
    echo "✗ Verification found $ERRORS issue(s)"
    exit 1
fi
echo "=========================================="
