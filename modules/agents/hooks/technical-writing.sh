#!/usr/bin/env bash
# An agent loads a skill only when it judges the skill relevant, so this hook asks for
# technical-writing every turn.
set -uo pipefail

printf 'Invoke the technical-writing skill if it is not loaded yet, and follow it for every response this session: chat replies, commit messages, docs, tickets, and PR text.\n'
