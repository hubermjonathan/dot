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

The `zsh` module puts the repo's `bin/` on `PATH`, and `dot` finds the repo from its own path, so it runs from any directory.

Module args are optional — omit them to act on every module. The interactive picker shows current state per module (`linked`, `partial`, `broken`, `diverged`, `unlinked`, `no-links`), the same as `dot status`.

`-v` / `--verbose` (any subcommand): after every successful subprocess step, dump the full captured `stdout`/`stderr` indented under the step's status line. Without it, output is suppressed on success and only surfaced on failure. Either way each step renders as a one-line spinner showing the most recent line of output. Modules with `setup.interactive = true` bypass the spinner so prompts work. Off a terminal, such as in a pipe or CI, each step prints its label and its final status line only.

Exit codes: `0` success. `1` when `dot doctor` leaves an issue or an orphan unfixed. `2` for any other failure, even one failed step.

## Build

```bash
./scripts/build.sh   # writes ./bin/dot
go test ./...        # run unit tests
```

## Modules

| Module    | Description |
|-----------|-------------|
| `rectangle` | Rectangle window manager (grid resize + move-to-display) |
| `apps`    | Brew + cask bundle: dust; bitwarden, google-chrome, spotify |
| `claude`  | Claude Code config: versioned `settings.json`, global `CLAUDE.md`, statusline, the `technical-writing` hook, and three plugin marketplaces: `hubermjonathan` from `hubermjonathan/skills`, `hubermjonathan-work` from `hubermjonathan/dot-work`, and `ou-claude-plugins` from `OfferUp/claude-plugins-ou` |
| `files`   | Shared images (profile, zoom background) under `~/Pictures` |
| `git`     | `.gitconfig` (incl. `core.excludesFile`), global `.gitignore`, `gh` CLI, interactive `gh auth login` on provision |
| `macos`   | Dock, Finder, menu bar, dark mode, monday week start, wallpaper, profile picture; Touch ID for `sudo` (`pam_tid.so` in `/etc/pam.d/sudo_local`) |
| `tailscale` | Tailscale, started at boot; joins the network on `dot install` |
| `tmux`    | `.tmux.conf` |
| `vim`     | `.vimrc`, noir colorscheme, Vundle and its plugins |
| `zsh`     | `.zshrc`, `.zshenv`, and the `conf.d/` auto-discovery directory |

## Module schema (`module.toml`)

```toml
[module]
# the module's name is its folder name
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
# Run during `dot doctor`. The check kinds are listed below.
checks = [
  { name = "config-dir", check = "dir_exists:~/.config/mytool" },
]

[setup]
interactive = false          # if true, post_link/provision get tty passthrough
post_link = [                # runs after `dot link` — MUST be idempotent
  { name = "create-local-rc", run = "touch ~/.myrc.local" },
]
provision = [                # runs only on `dot install` — one-shot side effects
  # `check` is optional; it runs in `dot doctor` and is skipped with its step
  { name = "auth", run = "mytool auth login", check = "command_succeeds:mytool auth status" },
]
```

Every step and check needs a `name`: kebab-case and unique within the module. A setup step needs `run`, an `sh -c` command, and can add a `check` that `dot doctor` runs. Skipping the step skips its check too. A `[health]` check has a `check` and no `run`.

### Health check kinds

A `check` is a `kind:arg` string. A `~/` in the argument expands to your home directory.

- `file_exists:<path>`: the path exists.
- `dir_exists:<path>`: the path exists and is a directory.
- `command_succeeds:<command>`: `sh -c <command>` exits 0.

### Skipping on one machine

`~/.dot-skips` lists what dot skips on this machine, one entry per line. It isn't tracked in the repo. `dot install` and `dot link` create it with a comment header if it's missing, so new and existing machines both get it.

```
# work Mac
macos/sudo-touchid    # one step, plus its check
apps                  # a whole module
```

`install`, `link`, `doctor`, `status`, `unlink`, and the picker all leave skipped modules and steps out. An entry that matches no module or step prints a warning. To skip something on a new machine before its first install, create `~/.dot-skips` before running the installer.

### Symlink behavior

- Source paths are relative to the module directory; targets are absolute and may use `~`.
- Directory symlinks are supported — e.g. `zsh/conf.d` → `~/.config/zsh` makes every file dropped into `conf.d/` live on the next shell start, no `[links]` edit needed.
- A symlink that points somewhere else is replaced with no backup.
- If a target already exists as a regular file, `dot link` and `dot doctor --fix` back it up to `~/.dotfiles-backup/<module>/<basename>.<utc-time>.<hash>` before replacing it.

### post_link vs provision

- `post_link` runs every `dot link`. Idempotent: safe to re-run. Use for things like creating placeholder files, running `osacompile`, or applying `defaults write`.
- `provision` runs only on `dot install`. Use for one-time bootstrap that talks to a remote (e.g. `gh auth login`).
- Set `interactive = true` when commands need stdin/stdout (auth flows, prompts).

## Zsh config

Drop a `.zsh` file in `modules/zsh/conf.d/` — the directory is symlinked to `~/.config/zsh` and `.zshrc` sources every file in it on shell start. No `module.toml` change required.

`.zshenv` sources `~/.zshrc.secrets`, then `~/.zshenv.local`, the machine-local file for environment every shell needs, such as a JDK on `PATH`. zsh reads `.zshenv` in every shell, including the non-interactive `zsh -c` that agents run, so both reach those shells too.

## Repository layout

```
scripts/install.sh   — curl-piped one-liner (Xcode CLT + clone + exec bootstrap)
scripts/bootstrap.sh — first-run installer (Homebrew + Go + build + dot install/link)
scripts/build.sh     — go build helper
cmd/dot/             — Cobra CLI commands (one file per subcommand)
internal/            — module discovery, linker, installer, doctor, TUI
modules/             — one subdirectory per module (each with module.toml)
bin/                 — built `dot` binary, gitignored; `bootstrap.sh` and `build.sh` write it
```
