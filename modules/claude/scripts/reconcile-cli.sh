#!/usr/bin/env bash
# Reconciles settings.work.json against an external CLI that overwrites ~/.claude/settings.json.
#
# Detection: sha of last settings.json seen (~/.claude/settings.cli.snapshot.json).
# On invocation:
#   1. If no snapshot → bootstrap (copy current settings.json), exit.
#   2. Compute leaf paths present in snapshot but missing/changed in current settings.json.
#      Those are "CLI dropped these" — prune matching entries from settings.work.json so
#      the next merge doesn't resurrect them.
#   3. User-authored keys in work.json (never in a snapshot) are untouched.
#   4. Refresh snapshot ← current settings.json.
#
# Run AFTER the CLI runs, BEFORE merge-settings.sh.

set -euo pipefail

machine_settings="${1:-$HOME/.claude/settings.json}"
work_settings="${2:-$HOME/.claude/settings.work.json}"
snapshot="${3:-$HOME/.claude/settings.cli.snapshot.json}"

if [ ! -f "$machine_settings" ]; then
  echo "reconcile-cli: machine file not found: $machine_settings" >&2
  exit 1
fi

if [ ! -f "$snapshot" ]; then
  cp "$machine_settings" "$snapshot"
  echo "reconcile-cli: bootstrapped snapshot → $snapshot"
  exit 0
fi

# Emit each leaf path as jq-array JSON, one per line: e.g. ["env","AWS_PROFILE"]
leaves() {
  jq -c '
    def walk(p):
      if type == "object" then
        if length == 0 then p
        else to_entries[] | (p + [.key]) as $q | (.value | walk($q))
        end
      elif type == "array" then p
      else p
      end;
    walk([])
  ' "$1"
}

# Compare snapshot vs current: emit paths whose leaf changed or vanished.
dropped_paths=$(
  jq -c -n --slurpfile snap "$snapshot" --slurpfile cur "$machine_settings" '
    def leaves:
      def walk(p):
        if type == "object" then
          if length == 0 then [{path: p, value: .}]
          else [to_entries[] | .key as $k | (.value | walk(p + [$k]))[]]
          end
        elif type == "array" then [{path: p, value: .}]
        else [{path: p, value: .}]
        end;
      walk([]);
    ($snap[0] | leaves) as $sn |
    ($cur[0]  | leaves) as $cu |
    ($cu | map({(.path | tojson): .value}) | add // {}) as $cu_map |
    $sn
    | map(select(($cu_map[.path | tojson] // null) != .value))
    | .[]
    | .path
  '
)

if [ -z "$dropped_paths" ]; then
  cp "$machine_settings" "$snapshot"
  exit 0
fi

# For each dropped path, delete matching entry from work.json (only if present there
# with the same value the CLI wrote — protects user-authored duplicates).
tmp=$(mktemp "${TMPDIR:-/tmp}/claude-work.XXXXXX")
trap 'rm -f "$tmp"' EXIT

cp "$work_settings" "$tmp"

while IFS= read -r path_json; do
  [ -z "$path_json" ] && continue
  # Snapshot's value at this path (what the CLI last wrote)
  snap_val=$(jq --argjson p "$path_json" 'getpath($p)' "$snapshot")
  work_val=$(jq --argjson p "$path_json" 'getpath($p) // null' "$tmp")
  if [ "$snap_val" = "$work_val" ]; then
    jq --argjson p "$path_json" 'delpaths([$p])' "$tmp" > "$tmp.new"
    mv "$tmp.new" "$tmp"
    printf 'reconcile-cli: pruned %s from work.json\n' "$(echo "$path_json" | jq -r 'join(".")')"
  fi
done <<< "$dropped_paths"

mv "$tmp" "$work_settings"
trap - EXIT

cp "$machine_settings" "$snapshot"
