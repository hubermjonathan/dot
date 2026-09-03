#!/usr/bin/env bash
# Emitted as additional context on SessionStart and UserPromptSubmit, so caveman is active
# every turn without depending on the skill auto-triggering or on CLAUDE.md being honoured.
#
# Active level lives in ~/.claude/caveman-mode (one word). Missing or unreadable means ultra.
# `off` prints nothing, which leaves responses in normal prose.
set -uo pipefail

file="$HOME/.claude/caveman-mode"
mode=ultra
[ -r "$file" ] && read -r mode <"$file" 2>/dev/null

case "$mode" in
  off) exit 0 ;;
  lite | full | ultra) ;;
  *) mode=ultra ;;
esac

printf 'Respond using the caveman skill in %s mode, for every response this session. Change level by writing lite|full|ultra|off to %s.\n' \
  "$mode" "$file"
