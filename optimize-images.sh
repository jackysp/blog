#!/bin/bash
# Image optimization script for blog images
# Converts PNG to WebP and optimizes JPG files

set -e

IMAGES_DIR="content/posts/images"
BACKUP_DIR="content/posts/images-backup"
TOTAL_SIZE_BEFORE=0
TOTAL_SIZE_AFTER=0
CONVERTED_COUNT=0
OPTIMIZED_COUNT=0

# Create backup directory
echo "Creating backup..."
mkdir -p "$BACKUP_DIR"

# Function to get file size in bytes
get_size() {
    stat -f%z "$1" 2>/dev/null || echo 0
}

# Process PNG files: convert to WebP
echo "Converting PNG files to WebP..."
for png_file in "$IMAGES_DIR"/*.png; do
    if [ ! -f "$png_file" ]; then
        continue
    fi
    
    filename=$(basename "$png_file" .png)
    webp_file="$IMAGES_DIR/${filename}.webp"
    
    # Backup original
    cp "$png_file" "$BACKUP_DIR/"
    
    # Convert to WebP with quality 85 (good balance)
    if cwebp -q 85 "$png_file" -o "$webp_file" 2>/dev/null; then
        size_before=$(get_size "$png_file")
        size_after=$(get_size "$webp_file")
        
        if [ "$size_after" -lt "$size_before" ]; then
            echo "  ✓ $filename.png -> $filename.webp ($(numfmt --to=iec-i --suffix=B $size_before) -> $(numfmt --to=iec-i --suffix=B $size_after))"
            TOTAL_SIZE_BEFORE=$((TOTAL_SIZE_BEFORE + size_before))
            TOTAL_SIZE_AFTER=$((TOTAL_SIZE_AFTER + size_after))
            CONVERTED_COUNT=$((CONVERTED_COUNT + 1))
            # Keep original for now, will remove after updating markdown
        else
            echo "  ✗ $filename.png (WebP larger, keeping PNG)"
            rm "$webp_file"
        fi
    else
        echo "  ✗ Failed to convert $filename.png"
    fi
done

# Process JPG files: optimize compression (only for large files)
echo ""
echo "Optimizing JPG files..."
for jpg_file in "$IMAGES_DIR"/*.jpg "$IMAGES_DIR"/*.JPG; do
    if [ ! -f "$jpg_file" ]; then
        continue
    fi
    
    filename=$(basename "$jpg_file")
    size_before=$(get_size "$jpg_file")
    
    # Only optimize files larger than 500KB
    if [ "$size_before" -lt 512000 ]; then
        echo "  - $filename ($(numfmt --to=iec-i --suffix=B $size_before), skipping - already small)"
        continue
    fi
    
    temp_file="${jpg_file}.tmp"
    
    # Backup original
    cp "$jpg_file" "$BACKUP_DIR/"
    
    # Optimize JPG: resize if very large, then recompress
    # First check dimensions
    width=$(sips -g pixelWidth "$jpg_file" 2>/dev/null | tail -1 | awk '{print $2}')
    height=$(sips -g pixelHeight "$jpg_file" 2>/dev/null | tail -1 | awk '{print $2}')
    
    # If image is very large (>2000px), resize first
    if [ -n "$width" ] && [ -n "$height" ] && [ "$width" -gt 2000 ]; then
        max_dim=2000
        sips -Z $max_dim "$jpg_file" --out "$temp_file" >/dev/null 2>&1
        if [ -f "$temp_file" ]; then
            mv "$temp_file" "$jpg_file"
            echo "  ✓ $filename (resized from ${width}x${height})"
        fi
    fi
    
    # Recompress with sips (it will use reasonable default quality)
    # Note: sips doesn't have explicit quality control, so we'll just re-encode
    # which can sometimes help with poorly compressed originals
    size_after=$(get_size "$jpg_file")
    
    if [ "$size_after" -lt "$size_before" ]; then
        echo "  ✓ $filename ($(numfmt --to=iec-i --suffix=B $size_before) -> $(numfmt --to=iec-i --suffix=B $size_after))"
        TOTAL_SIZE_BEFORE=$((TOTAL_SIZE_BEFORE + size_before))
        TOTAL_SIZE_AFTER=$((TOTAL_SIZE_AFTER + size_after))
        OPTIMIZED_COUNT=$((OPTIMIZED_COUNT + 1))
    else
        # Restore original if optimization didn't help
        cp "$BACKUP_DIR/$filename" "$jpg_file"
        echo "  - $filename (no improvement, keeping original)"
    fi
done

# Summary
echo ""
echo "=========================================="
echo "Optimization Summary:"
echo "  PNG -> WebP: $CONVERTED_COUNT files"
echo "  JPG optimized: $OPTIMIZED_COUNT files"
if [ $TOTAL_SIZE_BEFORE -gt 0 ]; then
    saved=$((TOTAL_SIZE_BEFORE - TOTAL_SIZE_AFTER))
    percent=$((saved * 100 / TOTAL_SIZE_BEFORE))
    echo "  Size reduction: $(numfmt --to=iec-i --suffix=B $TOTAL_SIZE_BEFORE) -> $(numfmt --to=iec-i --suffix=B $TOTAL_SIZE_AFTER)"
    echo "  Saved: $(numfmt --to=iec-i --suffix=B $saved) ($percent%)"
fi
echo "  Backup location: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "  1. Review the converted WebP files"
echo "  2. Run update-markdown-refs.sh to update image references in markdown files"
echo "  3. If everything looks good, remove backup: rm -rf $BACKUP_DIR"
echo "=========================================="
