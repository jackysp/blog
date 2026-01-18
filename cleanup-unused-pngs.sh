#!/bin/bash
# Remove unused PNG files that are not referenced in any markdown files

set -e

IMAGES_DIR="content/posts/images"
POSTS_DIR="content/posts"
REMOVED_COUNT=0
TOTAL_SIZE_FREED=0

echo "Checking for unused PNG files..."

for png_file in "$IMAGES_DIR"/*.png; do
    if [ ! -f "$png_file" ]; then
        continue
    fi
    
    filename=$(basename "$png_file")
    
    # Check if PNG is referenced in any markdown file
    if ! grep -r "$filename" "$POSTS_DIR"/*.md >/dev/null 2>&1; then
        size=$(stat -f%z "$png_file" 2>/dev/null || echo 0)
        echo "  Removing unused: $filename ($(numfmt --to=iec-i --suffix=B $size 2>/dev/null || echo ${size}B))"
        rm "$png_file"
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
        TOTAL_SIZE_FREED=$((TOTAL_SIZE_FREED + size))
    else
        echo "  Keeping (in use): $filename"
    fi
done

echo ""
echo "=========================================="
echo "Cleanup Summary:"
echo "  Unused PNG files removed: $REMOVED_COUNT"
if [ $TOTAL_SIZE_FREED -gt 0 ]; then
    echo "  Space freed: $(numfmt --to=iec-i --suffix=B $TOTAL_SIZE_FREED 2>/dev/null || echo ${TOTAL_SIZE_FREED}B)"
fi
echo "=========================================="
