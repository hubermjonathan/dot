#!/usr/bin/env bash
# Lists machine settings leaves that are absent from BOTH settings.repo.json
# and settings.work.json. Output is JSON: [{ "path": [...], "value": ... }, ...]
# so callers (skill, claude session) can act on each row programmatically.

set -euo pipefail

repo_settings="${1:-${CLAUDE_REPO_SETTINGS:-$HOME/.claude/settings.repo.json}}"
work_settings="${2:-${CLAUDE_WORK_SETTINGS:-$HOME/.claude/settings.work.json}}"
machine_settings="${3:-$HOME/.claude/settings.json}"

if [ ! -f "$machine_settings" ]; then
  echo "[]"
  exit 0
fi

tmp_empty=$(mktemp "${TMPDIR:-/tmp}/claude-empty.XXXXXX")
echo '{}' > "$tmp_empty"
trap 'rm -f "$tmp_empty"' EXIT

[ -f "$repo_settings" ] || repo_settings="$tmp_empty"
[ -f "$work_settings" ] || work_settings="$tmp_empty"

jq -n \
  --slurpfile machine "$machine_settings" \
  --slurpfile repo    "$repo_settings" \
  --slurpfile work    "$work_settings" '
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

  ($machine[0]) as $m |
  ($repo[0])    as $r |
  ($work[0])    as $w |
  [ ($m | leafpaths)[] as $p |
    (getin($m; $p)) as $mv |
    (getin($r; $p)) as $rv |
    (getin($w; $p)) as $wv |
    if ($mv | type) == "array" then
      ($mv - (($rv // []) + ($wv // []))) as $extra |
      if ($extra | length) > 0 then
        { path: $p, value: $extra, kind: "array_extra" }
      else empty end
    else
      if $mv == $rv or $mv == $wv then empty
      else { path: $p, value: $mv, kind: "scalar" } end
    end ]
'
