# dot

Personal macOS configuration managed by `dot`, a Go CLI that handles symlinks, Homebrew installs, and health checks for a set of pluggable modules.

Each subdirectory under `modules/` is a self-contained module: a `module.toml` plus its config files. The CLI walks that directory at runtime, so adding a new tool means adding a folder, with no code changes. Private config for the work machine lives in [hubermjonathan/dot-work](https://github.com/hubermjonathan/dot-work).

## Set up a machine

1. To skip modules or steps on this machine, create `~/.dot-skips` first, as [Skipping on one machine](#skipping-on-one-machine) describes.
2. Run the installer:

   ```bash
   curl -fsSL https://raw.githubusercontent.com/hubermjonathan/dot/main/scripts/install.sh | bash
   ```

   `install.sh` installs the Xcode command line tools, so `git` exists, and clones this repo into `~/Code/dot`. It then runs `bootstrap.sh`, which installs Homebrew and Go, builds `bin/dot`, and runs `dot install` and then `dot link` for every module. To clone somewhere else, set `DOT_DEST=<path>` or `DOT_REPO=<owner>/<name>`.

## Commands

```bash
dot                          # Interactive picker (TUI) — choose modules to install + link
dot link [mod...]            # Create symlinks; runs setup.post_link after
dot unlink [mod...]          # Remove symlinks
dot install [mod...]         # brew/cask install + setup.provision
dot doctor [--fix]           # Health check; --fix repairs symlinks
dot doctor --orphans         # Walk for stale repo symlinks (slow); --fix removes them
dot status [mod...] [--diff] # Per-module link state; --diff shows divergence vs repo
```

The `zsh` module puts the repo's `bin/` on `PATH`, and `dot` finds the repo from its own path, so it runs from any directory.

Module args are optional — omit them to act on every module. The interactive picker shows current state per module (`linked`, `partial`, `broken`, `diverged`, `unlinked`, `no-links`), the same as `dot status`.

`-v` or `--verbose` works with any subcommand. Each step shows as a one-line spinner with its latest line of output. When a step succeeds, its output stays hidden unless you pass `-v`. When a step fails, its full output always prints under the status line. A module with `setup.interactive = true` runs its `post_link` and `provision` steps on the terminal with no spinner, so prompts work. Its brew and cask steps still use the spinner. Off a terminal, such as in a pipe or CI, a step prints its label in place of the spinner.

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
| `agents`  | Coding agent config: installs Claude Code, links the global instructions (`instructions.md`, as `~/.claude/CLAUDE.md`), the hook scripts any agent can run (`hooks/`, as `~/.agents/hooks`), and, from `claude/`, Claude Code's `settings.json` (hook registrations, plugin marketplaces) and `scripts/` (statusline), creates `~/.agents/AGENTS.local.md`, and registers the [`blue-bubbles`](https://github.com/hubermjonathan/blue-bubbles) MCP server, which reads its token from `BLUE_BUBBLES_TOKEN` |
| `apps`    | Brew + cask bundle: dust; bitwarden, google-chrome, spotify |
| `files`   | Shared images (profile, zoom background) under `~/Pictures` |
| `git`     | `.gitconfig` (incl. `core.excludesFile`), global `.gitignore`, `gh` CLI, interactive `gh auth login` on provision |
| `macos`   | Dock, Finder, menu bar, Terminal's Basic profile, dark mode, monday week start, wallpaper, profile picture, Chrome as the default browser; Touch ID for `sudo` (`pam_tid.so` in `/etc/pam.d/sudo_local`) |
| `tailscale` | Tailscale, started at boot; joins the network on `dot install` |
| `t3code`  | T3 Code app and its server `settings.json` |
| `tmux`    | `.tmux.conf` |
| `vim`     | `.vimrc`, noir colorscheme, Vundle and its plugins |
| `zsh`     | `.zshrc`, `.zshenv`, the `conf.d/` auto-discovery directory, and the `dot.caf` LaunchDaemon behind `caf` |

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

`install`, `link`, `doctor`, `status`, `unlink`, and the picker all leave skipped modules and steps out. An entry that matches no module or step prints a warning.

### Symlink behavior

- Source paths are relative to the module directory; targets are absolute and may use `~`.
- A source can be a directory. Every file in it then shows up at the target, so a new file needs no `[links]` change. `zsh/conf.d` works this way.
- A symlink that points somewhere else is replaced with no backup.
- If a target exists and isn't a symlink, such as a file or a directory, `dot link` and `dot doctor --fix` move it to `~/.dotfiles-backup/<module>/<basename>.<utc-time>.<hash>` before linking.

### post_link vs provision

- `post_link` runs every `dot link`. Idempotent: safe to re-run. Use for things like creating placeholder files, applying `defaults write`, or copying a file that can't be a symlink.
- `provision` runs only on `dot install`. Use for one-time bootstrap that talks to a remote (e.g. `gh auth login`).
- Set `interactive = true` when commands need stdin/stdout (auth flows, prompts).

## Zsh config

Drop a `.zsh` file in `modules/zsh/conf.d/` — the directory is symlinked to `~/.config/zsh` and `.zshrc` sources every `.zsh` file in it on shell start. No `module.toml` change required.

`caf [on|off|status]` keeps the Mac awake: no idle sleep, no lid-close sleep, display on. The `dot.caf` LaunchDaemon does the work, so `caf` also turns on at every boot. `dot link zsh` copies `conf.d/caf.plist` to `/Library/LaunchDaemons/dot.caf.plist` with `sudo` and loads it, whenever the two differ or the job isn't loaded. `caf off` turns idle sleep and lid-close sleep back on until the next boot.

`.zshenv` sources `~/.zshrc.secrets`, then `~/.zshenv.local`, the machine-local file for environment every shell needs, such as a JDK on `PATH`. zsh reads `.zshenv` in every shell, including the non-interactive `zsh -c` that agents run, so both reach those shells too.

## Layout

| Path | What it is |
|---|---|
| `AGENTS.md` | Conventions for agents that edit this repo. Each `CLAUDE.md` links to the `AGENTS.md` beside it |
| `scripts/install.sh` | The installer `curl` runs: the Xcode command line tools, the clone, then `bootstrap.sh` |
| `scripts/bootstrap.sh` | First-run setup: Homebrew, Go, the build, then `dot install` and `dot link` |
| `scripts/build.sh` | Builds `bin/dot` |
| `cmd/dot/` | The Cobra CLI, one file per subcommand |
| `internal/` | Module discovery, the linker, installer, doctor, and picker |
| `modules/` | One folder per module, each with a `module.toml` |
| `bin/` | The built `dot` binary, gitignored. `bootstrap.sh` and `build.sh` write it |
