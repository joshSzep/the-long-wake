#!/bin/bash

# Build script for The Long Wake manuscript
# Joins all chapter files into a single MANUSCRIPT.md

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="$SCRIPT_DIR/MANUSCRIPT.md"
CHAPTERS_DIR="$SCRIPT_DIR/chapters"

# Function to get part display name from folder name
get_part_name() {
    case "$1" in
        "01-waking")   echo "1 - Waking" ;;
        "02-refusal")  echo "2 - Refusal" ;;
        "03-limbo")    echo "3 - Limbo" ;;
        "04-friction") echo "4 - Friction" ;;
        "05-motion")   echo "5 - Motion" ;;
        *)             echo "$1" ;;
    esac
}

# Start with the title
echo "# The Long Wake" > "$OUTPUT"
echo "" >> "$OUTPUT"

# Process each part folder in order
for part_folder in "$CHAPTERS_DIR"/*/; do
    part_name=$(basename "$part_folder")
    display_name=$(get_part_name "$part_name")
    
    # Add part heading
    echo "## $display_name" >> "$OUTPUT"
    echo "" >> "$OUTPUT"
    
    # Process each chapter file in the part folder
    for chapter_file in "$part_folder"*.md; do
        if [ -f "$chapter_file" ]; then
            # Read content and convert # Chapter to ### Chapter
            sed 's/^# Chapter/### Chapter/' "$chapter_file" >> "$OUTPUT"
            echo "" >> "$OUTPUT"
            echo "---" >> "$OUTPUT"
            echo "" >> "$OUTPUT"
        fi
    done
done

echo "Built manuscript: $OUTPUT"
