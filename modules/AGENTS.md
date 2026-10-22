# modules — config modules

Each subdirectory is one module. The README documents the `module.sh` functions, the skips file, and how links and backups behave.

## Adding a module

1. Create `modules/<name>/` with a `module.sh` and the config files it links. The README's module schema lists every function.
2. Add a check for each side effect `dot status` should verify: as the third argument of the step it verifies, or as a `check` call when no step matches. `dot status` already verifies every link.
3. Run `scripts/test.sh`. It checks that every `module.sh` parses.
4. Run `dot install <name>` if the module calls `formula`, `cask`, or `provision`. Then run `dot link <name>`. Install goes first because a `post_link` step can call a tool that install puts in place, such as `desktoppr` in `macos`.

## Gotchas

- `module.sh` is sourced by every command, including `dot status`, so it holds only calls to the six functions, never a top-level command. A bare `defaults write ...` line would run on every `dot status`. Put it in a `post_link` instead.
- `post_link` runs on every `dot link`, so guard each side effect, as in `test -f ... ||` or `grep -q ... ||`.
- A step reads only links from its own module. Modules run in name order, so a step that reads another module's link breaks when that module is skipped or renamed. That's why the profile picture lives in `macos`.
- `modules/agents/instructions.md` holds the global instructions for every project and is linked as `~/.claude/CLAUDE.md`. The `CLAUDE.md` files in this repo are different files: symlinks to the `AGENTS.md` beside them. In `agents`, files any agent reads sit at the module root, and files only one agent reads go in a folder named for it, such as `claude/`. A hook script whose output works in any agent goes in `hooks/`, linked as `~/.agents/hooks`, and each agent's own config registers it, as `claude/settings.json` does.
- `instructions.md` `@`-imports `~/.agents/AGENTS.local.md`, the machine-local file dot doesn't track, like `zsh`'s `~/.zshrc.local`. `agents` creates it empty on link. It lives under `~/.agents/` so any agent can read it.
- A link works only for an app that writes through the symlink. T3 Code and Claude Code do, so a change made in either app shows up as a dirty file in this repo. Open a PR from it with `dot push`, or revert it. Rectangle doesn't, so it gets an `apply.sh`.
- When a tool replaces `~/.claude/settings.json` instead of writing through it, the statusline shows `settings not linked to repo`. Run `dot link agents` to relink it. The tool's copy moves to `~/.dotfiles-backup/agents/`.
