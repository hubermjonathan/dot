# dot

Personal macOS configuration managed by `dot`, a Go CLI that handles symlinks, Homebrew installs, and health checks for a set of pluggable modules.

Each subdirectory under `modules/` is a self-contained module: a `module.toml` plus its config files. The CLI walks that directory at runtime, so adding a new tool means dropping in a folder — no code changes.

## Quick start (new machine)

```bash
curl -fsSL https://raw.githubusercontent.com/hubermjonathan/dot/main/scripts/install.sh | bash
```

`install.sh` installs Xcode CLT (so `git` exists), clones this repo into `~/Code/dot`, then execs `bootstrap.sh`, which installs Homebrew + Go, builds `bin/dot`, and runs `dot install` followed by `dot link` to apply every module.

Override with `DOT_DEST=<path>` or `DOT_REPO=<owner>/<name>`.

## Commands

```bash
dot                  # Interactive picker (TUI) — choose modules to install + link
dot link [mod...]    # Create symlinks; runs setup.post_link after
dot unlink [mod...]  # Remove symlinks
dot install [mod...] # brew/cask install + setup.provision
dot doctor [--fix]   # Health check; --fix repairs symlinks
dot doctor --orphans # Walk for stale repo symlinks (slow); --fix removes them
dot status [--diff]  # Per-module link state; --diff shows divergence vs repo
```

Module args are optional — omit them to act on every module. The interactive picker shows current state per module (`linked`, `partial`, `broken`, `unlinked`, `no-links`).

`-v` / `--verbose` (any subcommand): after every successful subprocess step, dump the full captured `stdout`/`stderr` indented under the step's status line. Without it, output is suppressed on success and only surfaced on failure. Either way each step renders as a one-line spinner showing the most recent line of output. Modules with `setup.interactive = true` bypass the spinner so prompts work.

Exit codes: `0` success, `1` partial failure, `2` fatal.

## Build

```bash
./scripts/build.sh   # writes ./bin/dot
go test ./...        # run unit tests
```

## Modules

| Module    | Description |
|-----------|-------------|
| `rectangle` | Rectangle window manager (grid resize + move-to-display) |
| `apps`    | Brew + cask bundle: dust, ollama; ankerwork, bitwarden, google-chrome, spotify; pulls gemma4:12b-mlx on install |
| `claude`  | Claude Code config: versioned `settings.json`, global `CLAUDE.md`, statusline |
| `files`   | Shared images (profile, zoom background) under `~/Pictures` |
| `ghostty` | Ghostty terminal emulator + config |
| `git`     | `.gitconfig`, `.gitignore`, `gh` CLI, interactive `gh auth login` on provision |
| `handy`   | Handy speech-to-text: seeds `settings_store.json` (parakeet model, right-option hotkey, ollama post-processing) |
| `macos`   | Dock, Finder, menu bar, dark mode, wallpaper, profile picture; Touch ID for `sudo` (`pam_tid.so` in `/etc/pam.d/sudo_local`) |
| `scripts` | AppleScript utilities compiled to `.app` bundles (Caffeinate, Format JSON, Connect AirPods) |
| `tmux`    | `.tmux.conf` |
| `vim`     | `.vimrc`, noir colorscheme, Vundle bootstrap |
| `zsh`     | `.zshrc` + `conf.d/` auto-discovery directory |

## Module schema (`module.toml`)

```toml
[module]
name = "mytool"
description = "What it is"

[links]
# source (relative to module dir) = target (absolute, ~ expanded at runtime)
"config"   = "~/.config/mytool/config"
".myrc"    = "~/.myrc"

[deps]
brew = ["mytool"]            # brew formulae

[apps]
cask = ["mytool-desktop"]    # brew casks

[health]
# Run during `dot doctor`. Three check kinds:
checks = [
  "file_exists:~/.myrc",
  "dir_exists:~/.config/mytool",
  "command_succeeds:mytool --version",
]

[setup]
interactive = false          # if true, post_link/provision get tty passthrough
post_link = [                # runs after `dot link` — MUST be idempotent
  "touch ~/.myrc.local",
]
provision = [                # runs only on `dot install` — one-shot side effects
  "mytool auth login",
]
```

### Symlink behavior

- Source paths are relative to the module directory; targets are absolute and may use `~`.
- Directory symlinks are supported — e.g. `zsh/conf.d` → `~/.config/zsh` makes every file dropped into `conf.d/` live on the next shell start, no `[links]` edit needed.
- If a target already exists as a regular file, `dot link` backs it up to `~/.dotfiles-backup/<module>/<basename>.<hash>` before replacing it.
- `dot doctor --fix` recreates broken/missing symlinks but does not back up — it expects `dot link` to have run before.

### post_link vs provision

- `post_link` runs every `dot link`. Idempotent: safe to re-run. Use for things like creating placeholder files, running `osacompile`, or applying `defaults write`.
- `provision` runs only on `dot install`. Use for one-time bootstrap that talks to a remote (e.g. `gh auth login`).
- Set `interactive = true` when commands need stdin/stdout (auth flows, prompts).

## Zsh config

Drop a `.zsh` file in `modules/zsh/conf.d/` — the directory is symlinked to `~/.config/zsh` and `.zshrc` sources every file in it on shell start. No `module.toml` change required.

## Repository layout

```
scripts/install.sh   — curl-piped one-liner (Xcode CLT + clone + exec bootstrap)
scripts/bootstrap.sh — first-run installer (Homebrew + Go + build + dot install/link)
scripts/build.sh     — go build helper
cmd/dot/             — Cobra CLI commands (one file per subcommand)
internal/            — module discovery, linker, installer, doctor, TUI
modules/             — one subdirectory per module (each with module.toml)
bin/                 — built `dot` binary (committed for bootstrap)
```
