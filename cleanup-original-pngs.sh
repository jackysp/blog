#!/bin/bash
# Remove original PNG files that have been successfully converted to WebP

set -e

IMAGES_DIR="content/posts/images"
REMOVED_COUNT=0
TOTAL_SIZE_FREED=0

echo "Cleaning up original PNG files (keeping those where WebP was larger)..."

for png_file in "$IMAGES_DIR"/*.png; do
    if [ ! -f "$png_file" ]; then
        continue
    fi
    
    filename=$(basename "$png_file" .png)
    webp_file="$IMAGES_DIR/${filename}.webp"
    
    # If WebP exists and is smaller, remove PNG
    if [ -f "$webp_file" ]; then
        png_size=$(stat -f%z "$png_file" 2>/dev/null || echo 0)
        webp_size=$(stat -f%z "$webp_file" 2>/dev/null || echo 0)
        
        if [ "$webp_size" -gt 0 ] && [ "$webp_size" -lt "$png_size" ]; then
            echo "  Removing $filename.png (WebP exists and is smaller)"
            rm "$png_file"
            REMOVED_COUNT=$((REMOVED_COUNT + 1))
            TOTAL_SIZE_FREED=$((TOTAL_SIZE_FREED + png_size))
        else
            echo "  Keeping $filename.png (WebP larger or doesn't exist)"
        fi
    fi
done

echo ""
echo "=========================================="
echo "Cleanup Summary:"
echo "  PNG files removed: $REMOVED_COUNT"
if [ $TOTAL_SIZE_FREED -gt 0 ]; then
    echo "  Space freed: $(numfmt --to=iec-i --suffix=B $TOTAL_SIZE_FREED)"
fi
echo "=========================================="
