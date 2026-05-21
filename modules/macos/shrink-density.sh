#!/usr/bin/env bash
# Set the main display to its densest scaled mode (more screen space, smaller UI).
set -euo pipefail

command -v displayplacer >/dev/null 2>&1 || exit 0

list=$(displayplacer list)

main_id=$(printf '%s\n' "$list" | awk '
  /^Persistent screen id:/ { id = $NF }
  /main display/ { print id; exit }
')
[ -n "${main_id:-}" ] || exit 0

mode=$(printf '%s\n' "$list" | awk -v id="$main_id" '
  /^Persistent screen id:/ { in_block = ($NF == id) }
  in_block && /mode [0-9]+:/ && /scaling:on/ {
    m = $2; sub(/:/, "", m)
    for (i = 3; i <= NF; i++) {
      if ($i ~ /^res:/) {
        split(substr($i, 5), dims, "x")
        pixels = dims[1] * dims[2]
        if (pixels > best) { best = pixels; best_mode = m }
      }
    }
  }
  END { if (best_mode != "") print best_mode }
')
[ -n "${mode:-}" ] || exit 0

displayplacer "id:${main_id} mode:${mode}" >/dev/null
