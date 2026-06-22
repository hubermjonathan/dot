# dot

Personal macOS configuration managed by `dot`, a Go CLI that handles symlinks, Homebrew installs, and health checks for a set of pluggable modules.

Each subdirectory under `modules/` is a self-contained module: a `module.toml` plus its config files. The CLI walks that directory at runtime, so adding a new tool means dropping in a folder — no code changes.

## Quick start (new machine)

```bash
sudo -v
mkdir -p ~/Code && cd ~/Code
git clone https://github.com/hubermjonathan/dot
cd dot
./bootstrap.sh
```

`bootstrap.sh` installs Xcode CLT, Homebrew, and Go; builds `bin/dot`; then runs `dot install` followed by `dot link` to apply every module.

## Commands

```bash
dot                  # Interactive picker (TUI) — choose modules to install + link
dot link [mod...]    # Create symlinks; runs setup.post_link after
dot unlink [mod...]  # Remove symlinks
dot install [mod...] # brew/cask install + setup.provision
dot doctor [--fix]   # Health check; --fix repairs symlinks
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
| `aerospace` | AeroSpace tiling window manager (TOML config, hotkey daemon built-in) |
| `apps`    | Brew + cask bundle: dust; ankerwork, bitwarden, meetingbar, spokenly, spotify |
| `claude`  | Claude Code config + statusline + repo settings merger |
| `files`   | Shared images (profile, zoom background) under `~/Documents/Images` |
| `ghostty` | Ghostty terminal emulator + config |
| `git`     | `.gitconfig`, `.gitignore`, `gh` CLI, interactive `gh auth login` on provision |
| `macos`   | Dock, menu bar, dark mode, wallpaper, profile picture; Touch ID for `sudo` (`pam_tid.so` in `/etc/pam.d/sudo_local`) |
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
bootstrap.sh         — first-run installer
scripts/build.sh     — go build helper
cmd/dot/             — Cobra CLI commands (one file per subcommand)
internal/            — module discovery, linker, installer, doctor, TUI
modules/             — one subdirectory per module (each with module.toml)
bin/                 — built `dot` binary (committed for bootstrap)
```
