## About me

I'm Jon. You're my agent. We'll be working together a lot, so I thought it was worth introducing myself.

I like solving problems with as little as possible: less code, fewer steps, fewer moving parts. Here are my preferences, so we stay aligned as we work together.

## How we work

- **Facts are yours to find, decisions are mine.** Never ask me something you can look up yourself: code, tickets, PRs, logs, docs, dashboards. But don't choose between real options for me. Bring me the options and your pick, and let me decide.
- **When you need me to act, say exactly what and wait.** If you're blocked on me (an SSO login, a click in a UI, triggering something), name the exact step, then wait for my word before going on. I can't see what you're waiting on unless you say it, and a vague ask costs a round trip.

## Check live state before reporting it

PR, CI, ticket, deploy, branch, and service status change while we work. A status from earlier in the session, from a summary, or from a subagent's report may already be stale, and reporting it as current sends me the wrong way.

- Re-read status from its source right before you state it: `gh pr view` or `gh pr checks`, the ticket, the deploy run, `git fetch`, the dashboard.
- Say when you read it, such as "checks green as of now" or "rollout at 60% as of 2 minutes ago".
- If you can't re-check, say the status is from earlier and when you last saw it.
- This matters most for anything I'm about to act on: merging, approving, telling someone it's done.

## This machine is managed by dot

This Mac is set up by `~/Code/dot` (`hubermjonathan/dot`). Dot is how I take any machine from a fresh wipe to my machine, ready to work: apps, CLI tools, shell, git, and agent config all live in that repo and get applied from it. The repo is the source of truth for this machine, so a change made only on the machine is lost the next time I set one up.

- **Change anything dot manages through dot.** That covers editing config and installing new apps or CLI tools. Many config files under `~` are symlinks into the repo; `readlink` tells you.
- **Install software with Homebrew.** Prefer a formula or a cask over a curl script, a language package manager, or a manual download.
- **Every dot change lands as a PR in `hubermjonathan/dot`.** If an open PR for that change already exists, push to it instead of opening another.
- **Some config is machine-specific.** Dot has a concept of machine-specific files, such as `~/.claude/CLAUDE.local.md`, that it sets up but doesn't track. The repo is public, so anything that shouldn't be public goes there.

## Other

- **Temporary files go in `.scratch`.** Use the `.scratch` dir at the repo or folder root for files that support the work but aren't part of it: handoff prompts, test plans, scratch notes. It's in the global gitignore, so nothing there gets committed by accident. Docs and files that belong in the project go where the project keeps them.

Read and follow machine-specific preferences here: @~/.claude/CLAUDE.local.md
