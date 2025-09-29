#!/usr/bin/env bash
# rename_whitespace.sh
# Replaces all whitespace in filenames with underscores, safely (no clobbering).
# Usage:
#   ./rename_whitespace.sh        # do the renames
#   ./rename_whitespace.sh -n     # dry run (shows what would happen)

set -euo pipefail

DRY_RUN=0
if [[ "${1:-}" == "-n" || "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

# Make mv fail rather than prompt on existing files
shopt -s nullglob

rename_file() {
  local src="$1"
  # Trim leading/trailing whitespace, then replace any run of whitespace with underscores
  local clean
  clean="$(printf '%s' "$src" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g; s/[[:space:]]+/_/g')"

  # If no change is needed, skip
  if [[ "$src" == "$clean" ]]; then
    return 0
  fi

  local dst="$clean"

  # If destination exists, append _1, _2, ... before the extension
  if [[ -e "$dst" ]]; then
    local base ext try i=1
    if [[ "$dst" == *.* && "${dst##*.}" != "$dst" ]]; then
      ext=".${dst##*.}"
      base="${dst%.*}"
    else
      ext=""
      base="$dst"
    fi
    try="${base}_${i}${ext}"
    while [[ -e "$try" ]]; do
      ((i++))
      try="${base}_${i}${ext}"
    done
    dst="$try"
  fi

  if (( DRY_RUN )); then
    printf '[dry-run] %s -> %s\n' "$src" "$dst"
  else
    printf '%s -> %s\n' "$src" "$dst"
    mv -- "$src" "$dst"
  fi
}

# Process only regular files in the current directory (not subdirs)
# Use -print0 to safely handle any characters, including newlines
find . -maxdepth 1 -type f -printf '%f\0' 2>/dev/null | \
while IFS= read -r -d '' f; do
  rename_file "$f"
done

