# modules — config modules

Each subdirectory is one module. The README documents the `module.toml` schema, the health check kinds, the skips file, and how links and backups behave.

## Adding a module

1. Create `modules/<name>/` with a `module.toml` and the config files it links. The README's module schema lists every field.
2. Add a `check` for each side effect `dot doctor` should verify: on the step it verifies, or in `[health].checks` when no step matches. `dot doctor` already verifies every link.
3. Run `go test ./...`. `dot` skips a module whose `module.toml` fails to load and prints only a warning, so `TestRepoModulesLoad` loads every module to catch it.
4. Run `dot install <name>` if the module has `[deps]`, `[apps]`, or `provision` steps. Then run `dot link <name>`. Install goes first because a `post_link` step can call a tool that install puts in place, such as `desktoppr` in `macos`.

## Gotchas

- `post_link` runs on every `dot link`, so guard each side effect, as in `test -f ... ||` or `grep -q ... ||`.
- `modules/agents/instructions.md` holds the global instructions for every project and is linked as `~/.claude/CLAUDE.md`. The `CLAUDE.md` files in this repo are different files: symlinks to the `AGENTS.md` beside them. In `agents`, files any agent reads sit at the module root, and files only one agent reads go in a folder named for it, such as `claude/`.
- `instructions.md` `@`-imports `~/.agents/AGENTS.local.md`, the machine-local file dot doesn't track, like `zsh`'s `~/.zshrc.local`. `agents` creates it empty on link. It lives under `~/.agents/` so any agent can read it.
- A link works only for an app that writes through the symlink. T3 Code and Claude Code do, so a change made in either app shows up as a dirty file in this repo. Commit it or revert it. Rectangle doesn't, so it gets an `apply.sh`.
- When a tool replaces `~/.claude/settings.json` instead of writing through it, the statusline shows `settings not linked to repo`. Run `dot doctor --fix` to relink it. The tool's copy moves to `~/.dotfiles-backup/agents/`.
