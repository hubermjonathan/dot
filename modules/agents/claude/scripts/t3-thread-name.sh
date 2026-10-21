#!/usr/bin/env bash
# T3 Code sets T3CODE_CLI_PATH in the sessions it starts. SessionStart runs before the first
# prompt, so the hook can't name the thread itself and leaves that to the agent.
set -uo pipefail

[ -n "${T3CODE_CLI_PATH:-}" ] || exit 0

printf 'This session is a T3 Code thread. Once you know the task, rename the thread with the t3-code `t3_thread_update` tool and `action: "rename"`. Name it `<ticket number>-<kebab-case task>`, with the ticket'"'"'s number but not its project key, as in `123-fix-login-redirect` for ABC-123. With no ticket, use the task alone.\n'
