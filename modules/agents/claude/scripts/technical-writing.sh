#!/usr/bin/env bash
# Emitted as additional context on SessionStart and UserPromptSubmit, so technical-writing is
# active every turn without depending on the skill auto-triggering or on CLAUDE.md being honoured.
#
# No config. Hooked means on. Drop the hook from settings.json to turn it off.
set -uo pipefail

printf 'Invoke the technical-writing skill if it is not loaded yet, and follow it for every response this session: chat replies, commit messages, docs, tickets, and PR text.\n'
