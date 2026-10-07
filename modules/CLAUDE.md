# modules — config modules

Each subdirectory is one module. Required: a `module.toml` plus the config files it links. The CLI walks this directory at runtime — no registration anywhere else.

## Adding a module

1. Create `modules/<name>/module.toml`.
2. Drop config files into the module directory.
3. Declare symlinks in `[links]`: `"source-relative" = "~/target-absolute"`.
4. Add brew formulae in `[deps].brew`, casks in `[apps].cask`.
5. Add `[setup].post_link` for idempotent setup, `[setup].provision` for one-shot bootstrap. Give each step a `name`.
6. Add checks so `dot doctor` can verify the module: a `check` on the step it verifies, or a named entry in `[health].checks` when no step matches.
7. `dot link <name>` (and `dot install <name>` if it pulls anything new from brew).

## `module.toml` schema

```toml
[module]
name = "mytool"           # must match directory name
description = "..."

[links]
# source path is relative to this module dir, target may use ~
"config"  = "~/.config/mytool/config"
".myrc"   = "~/.myrc"

[deps]
brew = ["mytool"]         # `brew install`

[apps]
cask = ["mytool-app"]     # `brew install --cask`

[health]
checks = [
  { name = "app-installed", check = "dir_exists:/Applications/MyTool.app" },
]

[setup]
interactive = false        # if true, post_link/provision get tty passthrough
post_link = [              # runs every `dot link` — MUST be idempotent
  { name = "create-local-rc", run = "touch ~/.myrc.local" },
]
provision = [              # runs only on `dot install` — one-shot
  { name = "auth", run = "mytool auth login", check = "command_succeeds:mytool auth status" },
]
```

## Steps and checks

Every `post_link` step, `provision` step, and `[health]` check is a table with a `name`. Names are kebab-case and unique within the module, because `~/.dot-skips` names them as `<module>/<name>`. `module.Load` rejects a step without a name, and `TestRepoModulesLoad` fails `go test` if any module in the repo doesn't load.

- Setup steps need `run`, an `sh -c` command. An optional `check` verifies the step in `dot doctor`, and skipping the step skips its check too.
- `[health]` checks have `check` and no `run`. Use them only for checks that no step owns, such as an app installed by a cask.
- Don't add a check for a file in `[links]`; `dot doctor` already verifies every link.

## Skips file

`~/.dot-skips` is machine-local and untracked, like `~/local.zsh`. One entry per line, `#` starts a comment:

- `<module>` skips the whole module.
- `<module>/<name>` skips one step or check.

`getModules` in `cmd/dot/link.go` applies it, so every command leaves skipped items out, and it prints each applied entry once per run. Entries that match nothing print a warning. `dot install` and `dot link` create the file with a comment header when it's missing.

## Sections cheat-sheet

| Section | When | Notes |
|---------|------|-------|
| `[module]` | Always | `name` should equal directory name |
| `[links]` | Optional | Files or directories. `~` expanded at runtime |
| `[deps].brew` | Optional | Formulae, installed via `dot install` |
| `[apps].cask` | Optional | Casks, installed via `dot install` |
| `[health].checks` | Optional | `{ name, check }` tables; `check` is a `kind:arg` string, see below |
| `[setup].post_link` | Optional | `{ name, run, check? }` tables. `run` is sh-exec, runs after every `dot link` |
| `[setup].provision` | Optional | `{ name, run, check? }` tables. `run` is sh-exec, runs only on `dot install` |
| `[setup].interactive` | Optional | Default false. True → setup commands inherit stdin/stdout/stderr |

## Health check kinds

- `file_exists:<path>` — `os.Stat` succeeds.
- `dir_exists:<path>` — `os.Stat` succeeds and is a directory.
- `command_succeeds:<sh -c arg>` — exit 0.

`~` is expanded inside the argument before the check runs.

## Directory symlinks

Use a directory entry in `[links]` (e.g. `"conf.d" = "~/.config/zsh"`) for auto-discovery. Files inside need no individual entry — drop a file into the directory and it's live next session. Pattern used by `zsh` (`conf.d`) and `scripts` (`src`, `icons`).

## Backup behaviour

`dot link` checks the target before linking:

- Already a symlink to the right source → skip.
- Already a symlink to the wrong source → replace (no backup; symlinks are cheap).
- Already a regular file → move to `~/.dotfiles-backup/<module>/<basename>.<6-hex>` then create the symlink.
- Missing → create.

`dot doctor --fix` calls the same `linker.Link` but with no backup dir; assumes prior `dot link` already migrated regular files.

## Gotchas

- `post_link` runs on **every** `dot link`. Always guard side effects (`test -f ...`, `grep -q ...`). It's the most common source of footguns.
- `provision` runs **only** on `dot install`, never on `dot doctor --fix`. Use it for things that must not run twice (e.g. `gh auth login`).
- Health checks with `~` are expanded at runtime — fine to embed `~/.config/...` directly.
- `[setup].interactive = true` is required for any command that prompts — without it, stdin is closed and the auth flow hangs.
- The `claude` module links `user-global.md` to `~/.claude/CLAUDE.md` and `settings.json` to `~/.claude/settings.json`. The targets describe what they become on the machine, not what they're called in this repo — see `modules/claude/`. It also `touch`es `~/.claude/CLAUDE.local.md` on link — the machine-local, un-versioned companion that `CLAUDE.md` `@`-imports (mirrors `zsh`'s `~/local.zsh`).
- Claude settings are one file: `modules/claude/settings.json` symlinked straight to `~/.claude/settings.json`. No layering, no merge step. Anything that writes to `~/.claude/settings.json` (Claude Code itself, work tooling) writes through the symlink and shows up as a dirty file in this repo — resolve those by hand and commit or revert. The statusline surfaces both failure modes: 📥 `settings uncommitted` (yellow) when the repo file has uncommitted changes, 🆘 `settings not linked to repo` (red) when `~/.claude/settings.json` is no longer a symlink (a tool replaced the file instead of writing in place — `dot doctor --fix` relinks it).

## Module catalogue

| Module | What it does |
|--------|--------------|
| `rectangle` | Rectangle window manager (grid resize + move-to-display) |
| `apps` | Brew + cask bundle (no symlinks): dust, ollama; ankerwork, bitwarden, google-chrome, spotify; pulls gemma4:12b-mlx on install |
| `claude` | Global Claude Code config (`user-global.md` → `~/.claude/CLAUDE.md`), versioned `settings.json`, statusline; declares the `hubermjonathan/skills` marketplace and enables its `skills` plugin, and keeps `technical-writing` always-on via a `SessionStart`/`UserPromptSubmit` hook running `scripts/technical-writing.sh` (no config, hooked means on). |
| `files` | Shared images under `~/Pictures` |
| `ghostty` | Ghostty terminal emulator + config |
| `git` | `.gitconfig` (sets `core.excludesFile = ~/.gitignore`), global `.gitignore` (`.DS_Store`, `.scratch/`, `**/.claude/settings.local.json`), `gh` install, interactive `gh auth login` on `dot install` |
| `handy` | Handy speech-to-text: merges `handy.json` into `~/Library/Application Support/com.pais.handy/settings_store.json`, pre-downloads the parakeet model |
| `macos` | `defaults write` for Dock, Finder, menu bar, dark mode, monday week start, wallpaper, profile picture; `pam_tid.so` for sudo Touch ID |
| `scripts` | AppleScript sources compiled to `.app` bundles in `~/Applications/Scripts` |
| `tmux` | `.tmux.conf` |
| `vim` | `.vimrc`, noir colorscheme, Vundle bootstrap |
| `zsh` | `.zshrc` + `conf.d/` auto-discovery directory |
