#!/usr/bin/env bash
# Counts machine settings leaves that are present in ~/.claude/settings.json
# but NOT in either ~/.claude/settings.repo.json or ~/.claude/settings.work.json.
#
# These are "untracked" settings — typically added by Claude Code itself or
# by company tooling writing directly to settings.json. The statusline uses
# the count as a nudge: every untracked leaf is a decision pending — does
# it belong in settings.work.json (machine-local) or settings.repo.json
# (everywhere)? Prints a single integer.

set -euo pipefail

repo_settings="${1:-${CLAUDE_REPO_SETTINGS:-$HOME/.claude/settings.repo.json}}"
work_settings="${2:-${CLAUDE_WORK_SETTINGS:-$HOME/.claude/settings.work.json}}"
machine_settings="${3:-$HOME/.claude/settings.json}"

if [ ! -f "$machine_settings" ]; then
  echo 0
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
  ($m | leafpaths) as $paths |
  reduce $paths[] as $p (0;
    (getin($m; $p)) as $mv |
    (getin($r; $p)) as $rv |
    (getin($w; $p)) as $wv |
    if ($mv | type) == "array" then
      # Array leaf is "tracked" if every element appears in repo OR work.
      ($mv - (($rv // []) + ($wv // []))) as $extra |
      if ($extra | length) > 0 then . + 1 else . end
    else
      if $mv == $rv or $mv == $wv then . else . + 1 end
    end)
'
