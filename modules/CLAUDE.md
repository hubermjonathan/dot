# modules — config modules

Each subdirectory is one module. Required: a `module.toml` plus the config files it links. The CLI walks this directory at runtime — no registration anywhere else.

## Adding a module

1. Create `modules/<name>/module.toml`.
2. Drop config files into the module directory.
3. Declare symlinks in `[links]`: `"source-relative" = "~/target-absolute"`.
4. Add brew formulae in `[deps].brew`, casks in `[apps].cask`.
5. Add `[setup].post_link` for idempotent setup, `[setup].provision` for one-shot bootstrap.
6. Add `[health].checks` so `dot doctor` can verify the module.
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
  "file_exists:~/.myrc",
  "dir_exists:~/.config/mytool",
  "command_succeeds:mytool --version",
]

[setup]
interactive = false        # if true, post_link/provision get tty passthrough
post_link = ["..."]        # runs every `dot link` — MUST be idempotent
provision = ["..."]        # runs only on `dot install` — one-shot
```

## Sections cheat-sheet

| Section | When | Notes |
|---------|------|-------|
| `[module]` | Always | `name` should equal directory name |
| `[links]` | Optional | Files or directories. `~` expanded at runtime |
| `[deps].brew` | Optional | Formulae, installed via `dot install` |
| `[apps].cask` | Optional | Casks, installed via `dot install` |
| `[health].checks` | Optional | `kind:arg` strings; see below |
| `[setup].post_link` | Optional | Sh-exec, runs after every `dot link` |
| `[setup].provision` | Optional | Sh-exec, runs only on `dot install` |
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
| `apps` | Brew + cask bundle (no symlinks): dust; ankerwork, bitwarden, spotify |
| `claude` | Global Claude Code config (`user-global.md` → `~/.claude/CLAUDE.md`), versioned `settings.json`, statusline |
| `files` | Shared images under `~/Pictures` |
| `ghostty` | Ghostty terminal emulator + config |
| `git` | `.gitconfig`, `.gitignore`, `gh` install, interactive `gh auth login` on `dot install` |
| `handy` | Handy speech-to-text: merges `handy.json` into `~/Library/Application Support/com.pais.handy/settings_store.json`, pre-downloads the parakeet model |
| `macos` | `defaults write` for Dock, Finder, menu bar, dark mode, wallpaper, profile picture; `pam_tid.so` for sudo Touch ID |
| `scripts` | AppleScript sources compiled to `.app` bundles in `~/Applications/Scripts` |
| `tmux` | `.tmux.conf` |
| `vim` | `.vimrc`, noir colorscheme, Vundle bootstrap |
| `zsh` | `.zshrc` + `conf.d/` auto-discovery directory |
