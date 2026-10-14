# modules — config modules

Each subdirectory is one module. The README documents the `module.toml` schema, the health check kinds, the skips file, and how links and backups behave.

## Adding a module

1. Create `modules/<name>/module.toml`.
2. Drop config files into the module directory.
3. Declare symlinks in `[links]`: `"source-relative" = "~/target-absolute"`.
4. Add brew formulae in `[deps].brew`, casks in `[apps].cask`.
5. Add `[setup].post_link` for idempotent setup, `[setup].provision` for one-shot bootstrap. Give each step a `name`.
6. Add checks so `dot doctor` can verify the module: a `check` on the step it verifies, or a named entry in `[health].checks` when no step matches.
7. `dot link <name>` (and `dot install <name>` if it pulls anything new from brew).

## Steps and checks

`module.Load` rejects a step without a name, and `TestRepoModulesLoad` fails `go test` if any module in the repo doesn't load.

Don't add a check for a file in `[links]`. `dot doctor` already verifies every link.

## Gotchas

- `post_link` runs on **every** `dot link`. Always guard side effects (`test -f ...`, `grep -q ...`). It's the most common source of footguns.
- The `claude` module links `user-global.md` to `~/.claude/CLAUDE.md` and `settings.json` to `~/.claude/settings.json`. The targets describe what they become on the machine, not what they're called in this repo — see `modules/claude/`. It also `touch`es `~/.agents/AGENTS.local.md` on link. That file is the machine-local companion, not tracked by dot, that `CLAUDE.md` `@`-imports, like `zsh`'s `~/.zshrc.local`. It lives under `~/.agents/`, not `~/.claude/`, so any agent can read it.
- Claude settings are one file: `modules/claude/settings.json` symlinked straight to `~/.claude/settings.json`. No layering, no merge step. Anything that writes to `~/.claude/settings.json` (Claude Code itself, work tooling) writes through the symlink and shows up as a dirty file in this repo — resolve those by hand and commit or revert. The statusline surfaces both failure modes: 📥 `settings uncommitted` (yellow) when the repo file has uncommitted changes, 🆘 `settings not linked to repo` (red) when `~/.claude/settings.json` is no longer a symlink (a tool replaced the file instead of writing in place — `dot doctor --fix` relinks it).
