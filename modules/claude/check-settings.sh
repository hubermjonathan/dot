#!/usr/bin/env bash
# Counts repo-required setting leaves that are missing or differ in
# the machine's ~/.claude/settings.json. Prints a single integer.
# Used by the statusline as a drift indicator.

set -euo pipefail

repo_settings="${1:-${CLAUDE_REPO_SETTINGS:-$HOME/.claude/settings.repo.json}}"
machine_settings="${2:-$HOME/.claude/settings.json}"

if [ ! -f "$repo_settings" ] || [ ! -f "$machine_settings" ]; then
  echo 0
  exit 0
fi

jq -n \
  --slurpfile machine "$machine_settings" \
  --slurpfile repo "$repo_settings" '
  # Repo "leaves" are paths whose value is a scalar or an array.
  # Arrays are treated as leaves so element ordering does not produce
  # spurious drift after the merge step deduplicates array entries.
  def leafpaths:
    [ paths as $p
      | select((getpath($p) | type) != "object")
      | select(any($p[]; type == "number") | not)
      | $p ];

  def getin($obj; $p):
    reduce $p[] as $k ($obj;
      if . == null then null
      elif (. | type) == "object" and (. | has($k)) then .[$k]
      else null end);

  ($repo[0]) as $r |
  ($machine[0]) as $m |
  ($r | leafpaths) as $paths |
  reduce $paths[] as $p (0;
    (getin($r; $p)) as $rv |
    (getin($m; $p)) as $mv |
    if ($rv | type) == "array" then
      if ($mv | type) != "array" then . + 1
      elif (($rv - $mv) | length) > 0 then . + 1
      else . end
    elif $rv == $mv then .
    else . + 1 end)
'
