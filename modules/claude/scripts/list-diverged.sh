#!/usr/bin/env bash
# Lists settings.repo.json leaves that are missing or have a different value
# in the machine's settings.json. Output is JSON:
#   [{ "path": [...], "repo_value": ..., "machine_value": ..., "kind": ... }]
#
# `kind` is one of: "missing" (machine has no value), "scalar_mismatch",
# "array_subset_missing" (some repo elements absent from machine array).

set -euo pipefail

repo_settings="${1:-${CLAUDE_REPO_SETTINGS:-$HOME/.claude/settings.repo.json}}"
machine_settings="${2:-$HOME/.claude/settings.json}"

if [ ! -f "$repo_settings" ] || [ ! -f "$machine_settings" ]; then
  echo "[]"
  exit 0
fi

jq -n \
  --slurpfile machine "$machine_settings" \
  --slurpfile repo    "$repo_settings" '
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

  ($repo[0])    as $r |
  ($machine[0]) as $m |
  [ ($r | leafpaths)[] as $p |
    (getin($r; $p)) as $rv |
    (getin($m; $p)) as $mv |
    if ($rv | type) == "array" then
      if ($mv | type) != "array" then
        { path: $p, repo_value: $rv, machine_value: $mv, kind: "missing" }
      else
        ($rv - $mv) as $missing |
        if ($missing | length) > 0 then
          { path: $p, repo_value: $rv, machine_value: $mv, missing: $missing, kind: "array_subset_missing" }
        else empty end
      end
    else
      if $rv == $mv then empty
      elif $mv == null then
        { path: $p, repo_value: $rv, machine_value: null, kind: "missing" }
      else
        { path: $p, repo_value: $rv, machine_value: $mv, kind: "scalar_mismatch" }
      end
    end ]
'
