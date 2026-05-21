#!/usr/bin/env bash
# Merges repo Claude settings into ~/.claude/settings.json.
# Objects are merged recursively, arrays are unioned (deduped),
# and on scalar conflicts the repo value wins. Machine-only keys
# (e.g. company tooling additions) are preserved.

set -euo pipefail

repo_settings="${1:-${CLAUDE_REPO_SETTINGS:-$HOME/.claude/settings.repo.json}}"
machine_settings="${2:-$HOME/.claude/settings.json}"

if [ ! -f "$repo_settings" ]; then
  echo "merge-settings: repo file not found: $repo_settings" >&2
  exit 1
fi

mkdir -p "$(dirname "$machine_settings")"
[ -f "$machine_settings" ] || echo '{}' > "$machine_settings"

tmp=$(mktemp "${TMPDIR:-/tmp}/claude-settings.XXXXXX")
trap 'rm -f "$tmp"' EXIT

jq -n \
  --slurpfile machine "$machine_settings" \
  --slurpfile repo "$repo_settings" '
  def deepmerge(a; b):
    if (a | type) == "object" and (b | type) == "object" then
      reduce ((a + b) | keys_unsorted[]) as $k ({};
        .[$k] = (
          if (a | has($k)) and (b | has($k)) then deepmerge(a[$k]; b[$k])
          elif (b | has($k)) then b[$k]
          else a[$k] end))
    elif (a | type) == "array" and (b | type) == "array" then
      (a + b) | unique
    else b end;
  deepmerge($machine[0]; $repo[0])
' > "$tmp"

# Atomic replace
mv "$tmp" "$machine_settings"
trap - EXIT
