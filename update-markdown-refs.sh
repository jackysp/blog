#!/bin/bash
# Update markdown files to reference WebP images instead of PNG

set -e

IMAGES_DIR="content/posts/images"
POSTS_DIR="content/posts"

echo "Updating markdown image references from PNG to WebP..."

# Find all markdown files
find "$POSTS_DIR" -name "*.md" -type f | while read md_file; do
    # Check if file contains PNG references
    if grep -q "/posts/images/.*\.png" "$md_file"; then
        echo "Processing: $md_file"
        
        # Create temporary file
        temp_file="${md_file}.tmp"
        
        # Replace .png with .webp in image references
        # Pattern: /posts/images/filename.png -> /posts/images/filename.webp
        sed 's|/posts/images/\([^)]*\)\.png|/posts/images/\1.webp|g' "$md_file" > "$temp_file"
        
        # Check if changes were made
        if ! cmp -s "$md_file" "$temp_file"; then
            mv "$temp_file" "$md_file"
            echo "  ✓ Updated image references"
        else
            rm "$temp_file"
            echo "  - No changes needed"
        fi
    fi
done

echo ""
echo "Done! Please review the changes and test your blog."
