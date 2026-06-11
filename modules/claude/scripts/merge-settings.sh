#!/usr/bin/env bash
# Merges work-local and repo-required Claude settings into ~/.claude/settings.json.
#
# Layering (right wins on scalar conflict):
#   machine  ⊕  work  ⊕  repo  →  machine
#
# Objects are merged recursively, arrays are unioned (deduped), and on
# scalar conflicts the rightmost value wins (repo > work > machine).
# Machine-only keys (uncategorized additions, e.g. work tooling that
# wrote directly to settings.json) are preserved so nothing is lost
# silently — `check-untracked.sh` flags them so the user can decide
# whether they belong in settings.work.json or settings.repo.json.

set -euo pipefail

repo_settings="${1:-${CLAUDE_REPO_SETTINGS:-$HOME/.claude/settings.repo.json}}"
work_settings="${2:-${CLAUDE_WORK_SETTINGS:-$HOME/.claude/settings.work.json}}"
machine_settings="${3:-$HOME/.claude/settings.json}"

if [ ! -f "$repo_settings" ]; then
  echo "merge-settings: repo file not found: $repo_settings" >&2
  exit 1
fi

mkdir -p "$(dirname "$machine_settings")"
[ -f "$machine_settings" ] || echo '{}' > "$machine_settings"
[ -f "$work_settings" ]    || echo '{}' > "$work_settings"

tmp=$(mktemp "${TMPDIR:-/tmp}/claude-settings.XXXXXX")
trap 'rm -f "$tmp"' EXIT

jq -n \
  --slurpfile machine "$machine_settings" \
  --slurpfile work    "$work_settings" \
  --slurpfile repo    "$repo_settings" '
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
  deepmerge(deepmerge($machine[0]; $work[0]); $repo[0])
' > "$tmp"

# Atomic replace
mv "$tmp" "$machine_settings"
trap - EXIT
