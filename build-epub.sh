#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANUSCRIPT="$SCRIPT_DIR/MANUSCRIPT.md"
BUILD_MANUSCRIPT_SCRIPT="$SCRIPT_DIR/build-manuscript.sh"
COVER_IMAGE="$SCRIPT_DIR/cover.png"
OUTPUT_EPUB="$SCRIPT_DIR/The Long Wake.epub"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

require_file() {
  if [[ ! -f "$1" ]]; then
    printf 'Required file not found: %s\n' "$1" >&2
    exit 1
  fi
}

require_command pandoc
require_file "$BUILD_MANUSCRIPT_SCRIPT"
require_file "$COVER_IMAGE"

bash "$BUILD_MANUSCRIPT_SCRIPT"
require_file "$MANUSCRIPT"

pandoc "$MANUSCRIPT" \
  --from markdown \
  --to epub3 \
  --toc \
  --toc-depth=2 \
  --split-level=2 \
  --metadata title="The Long Wake" \
  --metadata author="Joshua Szepietowski" \
  --metadata lang="en-US" \
  --resource-path="$SCRIPT_DIR" \
  --epub-cover-image="$COVER_IMAGE" \
  --output "$OUTPUT_EPUB"

printf 'Built EPUB: %s\n' "$OUTPUT_EPUB"
