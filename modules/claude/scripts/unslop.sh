#!/usr/bin/env bash
# Emitted as additional context on SessionStart and UserPromptSubmit, so unslop is active
# every turn without depending on the skill auto-triggering or on CLAUDE.md being honoured.
#
# No config. Hooked means on. Drop the hook from settings.json to turn it off.
set -uo pipefail

printf 'Apply the unslop skill to every response this session: strip AI tells from all prose, commit messages, docs and PR text.\n'
