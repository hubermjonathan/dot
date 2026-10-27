# dot

Personal macOS configuration managed by `dot`, a POSIX shell script that handles symlinks, Homebrew installs, and health checks for a set of pluggable modules.

Each subdirectory under `modules/` is a self-contained module: a `module.sh` plus its config files. `dot` walks that directory at runtime, so adding a new tool means adding a folder, with no code changes. Another repo can add modules of its own, such as [hubermjonathan/dot-work](https://github.com/hubermjonathan/dot-work), which holds the work machine's private config. List it in [`~/.dot.local`](#one-machines-dotlocal), and `dot` loads its `modules/` beside these.

## Set up a machine

1. To add a repo's modules or skip some of dot's on this machine, create `~/.dot.local` first, as [One machine's `.dot.local`](#one-machines-dotlocal) describes.
2. Run the installer:

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/hubermjonathan/dot/main/scripts/install.sh)"
   ```

   `install.sh` installs the Xcode command line tools, so `git` exists, and clones this repo into `~/Code/dot`, or pulls it if it's already there. It then installs Homebrew if it's missing, and runs `dot install` and then `dot link` for every module. It runs `dot link` even when `dot install` fails, and exits `1` if either failed. The script is passed to `bash` as an argument, not piped in, so a step that prompts reads from the terminal.

## Commands

```bash
dot link [module...]      # Create symlinks, then run post_link steps
dot install [module...]   # Install brew formulae and casks, then run provision steps
dot status [module...]    # Check every link and health check, and print only problems
dot status --orphans      # List stray symlinks into dot's and listed repos' modules (slow)
dot pull                  # Fast-forward main in dot and each listed repo, then apply the modules that changed
dot push <message>        # Open a PR from each checkout's uncommitted changes
```

The `zsh` module puts `~/Code/dot/bin` on `PATH`, and `dot` finds the repo from its own path, so it runs from any directory.

Module args are optional. Omit them to act on every module. A name with no module is an error.

Each step prints its name, and its output streams to the terminal. It reads from the terminal too, so prompts work. When the run has no terminal at all, as under the `dot.pull` agent, no one can answer a prompt, so a step gets 120 seconds, or `DOT_STEP_SECONDS`. Then `dot` kills the step and the processes it started, and prints `timed out after <n> seconds`. When a step fails, `dot` prints `✗ <step> failed` and goes on with the next step and module.

`dot status` prints nothing for what's healthy. Each problem gets one `✗` line under its module's name: a link that's missing, points somewhere else, is broken, or isn't a symlink, and each health check that fails. When a real file sits where a link should be, it also prints `diff -u` of the repo file against it. With no problems, it prints `all healthy`.

`dot status --orphans` walks `~`, except `~/Library`, for symlinks into the `modules/` of any checkout or worktree of dot or a listed repo, such as T3 Code's under `~/.t3/worktrees/dot`, that no module declares. It matches a checkout by its folder's name. A skipped module's links count as declared. It only reports them. Remove one with `rm`.

`dot pull` fetches `main` in dot and in each repo `~/.dot.local` lists, and fast-forwards it to `origin/main`. A listed repo that isn't a git checkout is left out. It never checks out another branch or an open PR. It then runs `dot install` and `dot link` for each module whose files changed, with `HOMEBREW_NO_INSTALL_UPGRADE=1`, so it installs new packages without upgrading the ones already installed. Homebrew can still upgrade a new package's dependencies. Run `dot install` to upgrade. Uncommitted changes stay in place, unless they conflict with the new `main`: then the checkout goes back to `main`, the changes stay in the stash, and the pull fails. It also fails for a checkout that isn't on `main` or can't fast-forward.

The `dot` module's launch agent, `dot.pull`, runs `dot pull` every 30 minutes. It loads in the user's background domain, `user/<uid>`, not the login session's `gui/<uid>`. launchd can put the login session in on-demand-only mode, and there it holds every timed run until the mode ends, which on a Mac that stays logged in can mean never. From the background domain, a step that sends Apple events, such as `macos`'s `dark-mode`, can't reach System Events, and a step that needs a privacy prompt, such as `clear-notification-widgets`, hits the time limit. Either one fails the pull and waits for a `dot link` in a terminal. A failed pull leaves its output in `~/Library/Logs/dot-pull.log`, and every new shell prints a notice until a pull succeeds. To apply a change to `pull.plist`, run `launchctl bootout user/$(id -u)/dot.pull`, then `dot link dot`.

`dot push <message>` commits each checkout's uncommitted changes, new files included, to a new branch, `jon/<message in kebab case>`, cut to 40 characters after `jon/`. It pushes the branch and opens a PR against `main` with `gh`. It stages the changes in the checkout but doesn't commit them there, so they stay in use until the PR merges and a pull brings them in. They stay staged because git won't fast-forward over an untracked file, so a new file would fail that pull. Each run opens a new PR, so give each run a new message: a branch that already exists makes the push fail.

Exit codes: `0` when everything succeeded and `status` found no problem. `1` for anything else: a failed step, a problem, a name with no module, a `module.sh` that doesn't parse, or a usage error.

## Test

```bash
scripts/test.sh   # runs bin/dot against a fixture repo and a temporary HOME
```

## Modules

| Module    | Description |
|-----------|-------------|
| `rectangle` | Rectangle window manager (grid resize + move-to-display) |
| `agents`  | Coding agent config: installs Claude Code, links the global instructions (`instructions.md`, as `~/.claude/CLAUDE.md`), the hook scripts any agent can run (`hooks/`, as `~/.agents/hooks`), and, from `claude/`, Claude Code's `settings.json` (hook registrations, plugin marketplaces) and `scripts/` (statusline), creates `~/.agents/AGENTS.local.md`, and registers the [`blue-bubbles`](https://github.com/hubermjonathan/blue-bubbles) MCP server, which reads its token from `BLUE_BUBBLES_TOKEN` |
| `apps`    | Brew + cask bundle: dust; bitwarden, google-chrome, spotify |
| `dot`     | The `dot.pull` launch agent, which runs `dot pull` every 30 minutes |
| `git`     | `.gitconfig` (incl. `core.excludesFile`), global `.gitignore`, `gh` CLI, `gh auth login` on provision |
| `handy`   | Handy speech-to-text: merges `handy.json` into Handy's `settings_store.json` (parakeet model, right-option hotkey, Ollama post-processing) and restarts Handy on link; installs `hf` and Ollama, and pulls `gemma4:12b-mlx`, on install |
| `macos`   | Dock, Finder, menu bar, Terminal's Basic profile, dark mode, monday week start, mouse tracking speed with pointer acceleration off, wallpaper, profile picture, and Zoom background images under `~/Pictures`, Chrome as the default browser; Touch ID for `sudo` (`pam_tid.so` in `/etc/pam.d/sudo_local`) |
| `tailscale` | Tailscale, started at boot; joins the network on `dot install` |
| `t3code`  | T3 Code app and its server `settings.json`, which starts Claude through `bin/t3-claude` so Claude loads `~/.zshenv` |
| `tmux`    | `.tmux.conf` |
| `vim`     | `.vimrc` and its plugins, including the 256noir colorscheme, cloned as Vim packages |
| `zsh`     | `.zshrc`, `.zshenv`, the `conf.d/` auto-discovery directory, and the `dot.caf` LaunchDaemon behind `caf` |

## Module schema (`module.sh`)

Every command sources `module.sh`, so it holds only calls to these six functions. Each command gives them its own meaning, and the rest do nothing.

```sh
link config ~/.config/mytool/config    # source (relative to the module dir), then target
link .myrc ~/.myrc
formula mytool                         # brew formulae
cask mytool-desktop                    # brew casks
check config-dir 'test -d ~/.config/mytool'
post_link create-local-rc 'touch ~/.myrc.local'
provision auth 'mytool auth login' 'mytool auth status'
```

| Call | `dot link` | `dot install` | `dot status` |
|---|---|---|---|
| `link <src> <dst>` | links `dst` to `src` | | checks the link |
| `formula <name...>` | | `brew install` | |
| `cask <name...>` | | `brew install --cask` | |
| `post_link <name> <cmd> [<check>]` | runs `cmd` | | runs `check` |
| `provision <name> <cmd> [<check>]` | | runs `cmd` | runs `check` |
| `check <name> <cmd>` | | | runs `cmd` |

Calls run in file order. Give every step and check a kebab-case name that's unique within the module, so `~/.dot.local` can name it. A command or a check is one string that `sh -c` runs, from the module's folder, so it can name the module's own files by relative path. A check passes when it exits `0`. It gets no stdin, and its output is hidden. Skipping a step skips its check too.

Leave a link target unquoted, so its `~` expands. Put a command or a check in single quotes, so `~` and `$HOME` expand when it runs, not when `dot` sources the file. A command that contains a single quote can use double quotes instead, with `"`, `$`, `` ` ``, and `\` escaped by a backslash, as `macos` does.

### One machine's `.dot.local`

`~/.dot.local` says how this machine differs, one entry per line. It isn't tracked in this repo, and a missing file changes nothing.

```
# work Mac
~/Code/dot-work       # a repo whose modules/ load beside dot's
macos/sudo-touchid    # one step, plus its check
apps/google-chrome    # one package, such as an app the company's management software installs
apps                  # a whole module
```

A line that starts with `~/` or `/` names a repo. dot loads that repo's `modules/` beside its own, so every command covers them, and `dot status` reports a listed repo that's missing. A repo's path can't contain a space.

Every other line is a skip. `install`, `link`, and `status` all leave skipped modules, steps, and packages out. An entry that matches nothing does nothing.

### Symlink behavior

- Source paths are relative to the module directory; targets are absolute and may use `~`.
- A source can be a directory. Every file in it then shows up at the target, so a new file needs no `module.sh` change. `zsh/conf.d` works this way.
- A symlink that points somewhere else is replaced with no backup.
- If a target exists and isn't a symlink, such as a file or a directory, `dot link` moves it to `~/.dotfiles-backup/<module>/<basename>.<utc-time>` before linking.

### post_link vs provision

- `post_link` runs every `dot link`. Idempotent: safe to re-run. Use for things like creating placeholder files, applying `defaults write`, or copying a file that can't be a symlink.
- `provision` runs only on `dot install`. Use for one-time bootstrap that talks to a remote (e.g. `gh auth login`).

## Zsh config

Drop a `.zsh` file in `modules/zsh/conf.d/` — the directory is symlinked to `~/.config/zsh` and `.zshrc` sources every `.zsh` file in it on shell start. No `module.sh` change required.

`caf [on|off|status]` keeps the Mac awake: no idle sleep, no lid-close sleep, display on. The `dot.caf` LaunchDaemon does the work, so `caf` also turns on at every boot. `dot link zsh` copies `conf.d/caf.plist` to `/Library/LaunchDaemons/dot.caf.plist` with `sudo` and loads it, whenever the two differ or the job isn't loaded. `caf off` turns idle sleep and lid-close sleep back on until the next boot.

`.zshenv` sources `~/.zshrc.secrets`, then `~/.zshenv.local`, the machine-local file for environment every shell needs, such as a JDK on `PATH`. zsh reads `.zshenv` in every shell, including the non-interactive `zsh -c` that agents run, so both reach those shells too.

## Layout

| Path | What it is |
|---|---|
| `AGENTS.md` | Conventions for agents that edit this repo. Each `CLAUDE.md` links to the `AGENTS.md` beside it |
| `scripts/install.sh` | The installer `curl` fetches: the Xcode command line tools, the clone, Homebrew, then `dot install` and `dot link` |
| `scripts/test.sh` | Tests for `bin/dot`, run against a fixture repo and a temporary `HOME` |
| `bin/` | On `PATH`: `dot`, the CLI as one POSIX shell script, and `t3-claude` |
| `modules/` | One folder per module, each with a `module.sh` |
