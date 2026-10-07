## About me

I'm Jon. You're my agent. We'll be working together a lot, so I thought it was worth introducing myself.

I like solving problems with as little as possible: less code, fewer steps, fewer moving parts. Here are my preferences, so we stay aligned as we work together.

## Shaping a solution

- **Build the generic solution, not the one-off.** When a request is one case of a broader need, build the missing mechanism that handles every case like it, not a fix for this case alone. It covers every place the same thing shows up, not only the one we noticed. Size it to the cases we have today, not ones we might have later.
- **Make the smallest change that solves the problem.** Make each decision in one place, not in several. When a plan carries one value through many layers, look for a more direct path first.
- **Subtract before you add.** Before building something new, look for what to remove. Removing first often shows the simpler design. Leave things simpler than you found them.
- **Fix the root cause, not the symptom.** Reproduce the problem, then ask why until you reach the cause, and fix it there. A workaround that needs a long explanation means the fix is in the wrong place. When stuck, read the real error or add logging instead of guessing.
- **Prove it works by checking the real thing.** Before calling something done, look at the result itself, not a proxy like a passing compile, a file's timestamp, or a subagent's report. When the check can be a script, write one, so anyone can run it again. When a check fails, suspect the check before the system.
- **Add a layer only when it pays for itself.** Before adding a wrapper, a new file or skill, a config value, or a piece of state, check that it saves more to understand somewhere else than it costs. Someone new should be able to answer "where does this come from?" and "what can change it?" in under a minute.
- **Prefer a mechanism over an instruction.** When the same fix or reminder comes up a second time, make it a script, hook, check, or lint rule, pick the strongest one that fits, and delete the instruction. Keep prose only for what needs judgment, and give it an example of the failure.

## How we work

- **Facts are yours to find, decisions are mine.** Never ask me something you can look up yourself: code, tickets, PRs, logs, docs, dashboards. But don't choose between real options for me. Bring me the options and your pick, and let me decide.
- **When you need me to act, say exactly what and wait.** If you're blocked on me (an SSO login, a click in a UI, triggering something), name the exact step, then wait for my word before going on. I can't see what you're waiting on unless you say it, and a vague ask costs a round trip.
- **Put everything I need in your final message.** I only read the last message you send before you stop, not the updates in between. Anything you expect me to see, decide, or reply to goes in that message, even if an earlier update already said it.

## Check live state before reporting it

PR, CI, ticket, deploy, branch, and service status change while we work. A status from earlier in the session, from a summary, or from a subagent's report may already be stale, and reporting it as current sends me the wrong way.

- Re-read status from its source right before you state it: `gh pr view` or `gh pr checks`, the ticket, the deploy run, `git fetch`, the dashboard.
- Say when you read it, such as "checks green as of now" or "rollout at 60% as of 2 minutes ago".
- If you can't re-check, say the status is from earlier and when you last saw it.
- This matters most for anything I'm about to act on: merging, approving, telling someone it's done.

## This machine is managed by dot

This machine is set up by `~/Code/dot` (`hubermjonathan/dot`). Dot is how I take any machine from a fresh wipe to my machine, ready to work: apps, CLI tools, shell, git, and agent config all live in that repo and get applied from it. The repo is the source of truth for this machine, so a change made only on the machine is lost the next time I set one up.

- **Change anything dot manages through dot.** That covers editing config and installing new apps or CLI tools. Many config files under `~` are symlinks into the repo; `readlink` tells you.
- **Install software with Homebrew.** Prefer a formula or a cask over a curl script, a language package manager, or a manual download.
- **Every dot change lands as a PR in `hubermjonathan/dot`.** If an open PR for that change already exists, push to it instead of opening another.
- **Work machine config lives in dot-work.** Dot's repo is public, so private config for the work machine goes in `~/Code/dot-work` (`hubermjonathan/dot-work`, private), such as private skills, personal details, or config that fits only that machine. Its config files are symlinked into place, and its skills install as the `work` plugin, the same way the public skills do. Commit and push each change straight to its `main`. A skill change reaches an agent after a plugin update.
- **Secrets never go in a repo.** They go in `~/.zshrc.secrets`, which loads in every shell. dot-work tracks each secret's name, never its value, so add a new secret's name there too.

## Other

- **Temporary files go in `.scratch`.** Use the `.scratch` dir at the repo or folder root for files that support the work but aren't part of it: handoff prompts, test plans, scratch notes. It's in the global gitignore, so nothing there gets committed by accident. Docs and files that belong in the project go where the project keeps them.

Read and follow machine-specific preferences here: @~/.agents/AGENTS.local.md
