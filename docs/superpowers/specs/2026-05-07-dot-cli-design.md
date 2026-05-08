# Dot CLI — Dotfiles Management Tool

## Goal

Replace the current copy-based shell scripts with a Go CLI (`dot`) that manages dotfiles via symlinks, installs applications, and can diagnose/repair its own state. Single source of truth: edit configs in the repo, changes are live immediately.

## Commands

| Command | Description |
|---------|-------------|
| `dot` | Interactive Bubble Tea TUI — pick modules to link/unlink/install |
| `dot link [module...]` | Create symlinks for all or specified modules |
| `dot unlink [module...]` | Remove symlinks |
| `dot install [module...]` | Install brew deps + apps for modules |
| `dot doctor [--fix]` | Health check; shows issues + fix actions. `--fix` auto-repairs everything |
| `dot status` | Overview of module states (linked/unlinked/broken/new) |
| `dot init <name>` | Scaffold a new module directory with empty module.toml |

### Interactive Mode (`dot`)

When invoked with no subcommand, presents a Bubble Tea multi-select showing all modules with their current state (linked/unlinked/partial/broken). User picks which to set up. Runs install + link for selected.

### Doctor Behavior

1. Discovers all modules
2. For each module checks: symlinks correct, brew deps installed, cask apps installed, custom health checks pass, new files in module dir not yet declared
3. Prints grouped report: module → issues → what fix would do
4. With `--fix`: executes all fix actions (create symlinks, install packages, run post_link commands)
5. `new_file` issues are informational only (no auto-fix) — doctor suggests adding them to module.toml. Files inside directory-linked dirs (like `conf.d/`) are exempt — they're covered by the directory symlink.

### Execution Model

| Command | What it runs |
|---------|-------------|
| `dot install [module...]` | Brew deps → cask apps → provision commands |
| `dot link [module...]` | Create symlinks → post_link commands |
| `dot doctor --fix` | Create symlinks + install deps/apps + post_link. Does NOT run provision. |
| `dot` (interactive) | Runs install then link for selected modules (full setup). |

`provision` is intentionally only triggered by `dot install` — these are interactive/destructive one-time tasks (like SSH key generation) that should never auto-run.

### Error Handling

- **Continue-on-error by default**: if one module fails during `dot link` or `dot install`, report the error and continue to next module. Print summary at end.
- **Exit codes**: 0 = all success, 1 = partial failure (some modules failed), 2 = fatal (couldn't start at all)
- **`post_link` failures**: warn and continue; do not rollback symlinks already created.
- **`dot doctor --fix`**: attempts all fixes, reports which succeeded and which failed at end.

## Module System

### Directory Structure

Each tool gets a directory under `modules/` containing a `module.toml` and the actual config files.

```
modules/
├── git/
│   ├── module.toml
│   ├── .gitconfig
│   └── .gitignore
├── zsh/
│   ├── module.toml
│   ├── .zshrc           (sources all *.zsh from ~/.config/zsh/)
│   └── conf.d/          (directory symlinked to ~/.config/zsh — drop files here)
│       ├── git.zsh
│       ├── work.zsh
│       ├── shared.zsh
│       └── homebrew.zsh
├── vim/
│   ├── module.toml
│   ├── .vimrc
│   └── noir.vim
├── ghostty/
│   ├── module.toml
│   └── config           (to be created)
├── claude/
│   ├── module.toml
│   └── (claude config files)
├── tmux/
│   ├── module.toml
│   └── .tmux.conf       (to be created)
├── homebrew/
│   ├── module.toml
│   └── Brewfile.base
├── raycast/
│   ├── module.toml
│   └── raycast.rayconfig
└── apps/
    └── module.toml      (standalone apps with no config files)
```

### module.toml Schema

```toml
[module]
name = "string"           # Module identifier
description = "string"    # Shown in interactive picker and status

[links]
# Keys: file path relative to module directory
# Values: absolute target path (~ expanded at runtime)
"source_file" = "~/target_path"

[deps]
brew = ["formula1", "formula2"]   # Homebrew formulae

[apps]
cask = ["app1", "app2"]           # Homebrew casks

[health]
# Custom checks beyond automatic symlink/dep/app verification
# Supported types: file_exists, dir_exists, command_succeeds
checks = [
  "file_exists:~/.ssh/id_ed25519",
  "dir_exists:~/.config/zsh",
  "command_succeeds:git config user.name",
]

[setup]
# Commands run after linking. MUST be idempotent (safe to re-run).
# Use guards like `command -v` or `test -e` for non-idempotent operations.
post_link = [
  "git config --global core.excludesfile ~/.gitignore",
]

# One-time provisioning tasks (interactive, run only via `dot install`)
# These are NOT run by `dot doctor --fix`
provision = [
  "ssh-keygen -t ed25519 -C 'hubermjonathan@gmail.com' -f ~/.ssh/id_ed25519 -N '' -q",
]
```

### Zsh Module — Auto-Discovery Pattern

The zsh module uses a directory symlink instead of individual file symlinks:

```toml
# modules/zsh/module.toml
[module]
name = "zsh"
description = "Zsh shell configuration"

[links]
".zshrc" = "~/.zshrc"
"conf.d" = "~/.config/zsh"    # Directory symlink

[deps]
brew = ["zsh"]
```

The `.zshrc` sources everything in `~/.config/zsh/`:
```zsh
for config in "$HOME/.config/zsh/"*.zsh; do
  source "${config}"
done
```

To add new shell config: drop a `.zsh` file in `modules/zsh/conf.d/`. It's immediately active — no module.toml edit, no re-linking.

### Module Discovery

The CLI walks `modules/` at runtime, reads each `module.toml`, and builds the module list. No central registry file to maintain.

## Go Architecture

```
cmd/dot/
├── main.go              # Cobra root command setup
├── link.go              # dot link
├── unlink.go            # dot unlink
├── install.go           # dot install
├── doctor.go            # dot doctor
├── status.go            # dot status
├── init_cmd.go          # dot init
└── interactive.go       # dot (no args) — Bubble Tea TUI

internal/
├── module/
│   ├── module.go        # Module struct, Load(), state queries
│   ├── discover.go      # Walk modules/ dir, find all module.toml files
│   └── toml.go          # TOML deserialization types
├── linker/
│   └── linker.go        # Symlink create/remove/verify/detect broken
├── doctor/
│   └── doctor.go        # Health checks, issue collection, fix execution
├── installer/
│   └── installer.go     # brew install, brew install --cask, idempotent
└── tui/
    └── picker.go        # Bubble Tea multi-select component
```

### Dependencies

- `github.com/spf13/cobra` — CLI framework
- `github.com/BurntSushi/toml` — TOML parsing
- `github.com/charmbracelet/bubbletea` — TUI framework
- `github.com/charmbracelet/lipgloss` — TUI styling

### Key Types

```go
type Module struct {
    Name        string
    Description string
    Path        string            // absolute path to module dir
    Links       map[string]string // source -> target
    Deps        Deps
    Apps        Apps
    Health      []string
    PostLink    []string
    Provision   []string
}

type Issue struct {
    Module      string
    Type        string // "symlink", "dep", "app", "health", "new_file"
    Description string
    FixAction   func() error // nil for informational-only issues (new_file)
}
```

### Go Module Path

`github.com/hubermjonathan/dotfiles`

## Bootstrap (New Machine)

```bash
#!/bin/bash
# bootstrap.sh — run on a fresh machine

# Install Homebrew
if ! command -v brew &>/dev/null; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Go
brew install go

# Build dot
cd "$(dirname "$0")"
go build -o bin/dot ./cmd/dot

# Install everything (deps, apps, provision tasks) then link configs
./bin/dot install
./bin/dot link
```

## Symlink Strategy

- Before creating a symlink, check if target already exists:
  - If it's already a correct symlink → skip
  - If it's a file → back up to `~/.dotfiles-backup/<module>/<file>` then replace with symlink
  - If it's a broken symlink → remove and recreate
- Parent directories created automatically if missing (e.g., `~/.config/zsh/`, `~/.vim/colors/`)
- `dot unlink` removes the symlink only — does not restore backups (the config content lives in the repo, restoring an old backup would lose changes). Backups exist as safety net for `dot link`, not for round-tripping.

## Documentation Strategy

### CLAUDE.md Files

Short, actionable files at key points in the repo for LLM context:

```
CLAUDE.md                    # Repo-level: what this is, how to build, commit conventions
cmd/dot/CLAUDE.md            # CLI layer: how commands are structured, adding new commands
internal/CLAUDE.md           # Internal packages: patterns, conventions, testing approach
modules/CLAUDE.md            # Module system: how to add modules, module.toml format
```

Each CLAUDE.md should be:
- Under 40 lines
- Focus on "how to contribute here" not "what this does"
- Include gotchas and non-obvious conventions

### README.md

Human-facing documentation at repo root:
- What this repo does
- How to bootstrap on a new machine
- How to add a new tool/module
- Available `dot` commands (brief)

## Migration Plan

### Files that exist today → move to modules/

| Current location | New location | Notes |
|-----------------|--------------|-------|
| `zsh/.zshrc` | `modules/zsh/.zshrc` | Rewrite to source glob from `~/.config/zsh/` |
| `zsh/shared.zsh` | `modules/zsh/conf.d/shared.zsh` | Split: git aliases → `git.zsh` |
| `zsh/homebrew.zsh` | `modules/zsh/conf.d/homebrew.zsh` | Exists |
| `git/.gitignore` | `modules/git/.gitignore` | Exists |
| `vim/.vimrc` | `modules/vim/.vimrc` | Exists |
| `vim/noir.vim` | `modules/vim/noir.vim` | Exists |
| `homebrew/Brewfile.base` | `modules/homebrew/Brewfile.base` | Exists |
| `raycast/raycast.rayconfig` | `modules/raycast/raycast.rayconfig` | Exists |

### Files to create during migration

| File | Purpose |
|------|---------|
| `modules/git/.gitconfig` | Static gitconfig (replaces dynamic `git config` commands) |
| `modules/zsh/conf.d/git.zsh` | Git aliases extracted from shared.zsh |
| `modules/zsh/conf.d/work.zsh` | Placeholder for work-specific shell config |
| `modules/ghostty/config` | Ghostty terminal config |
| `modules/tmux/.tmux.conf` | Tmux configuration |
| `modules/claude/` | Claude Code config files |

### SSH Key Handling

SSH key generation is an interactive provisioning task. It lives in `modules/git/module.toml` under `[setup] provision` — only runs via `dot install git`, never via `dot doctor --fix`. The health check `file_exists:~/.ssh/id_ed25519` reports if the key is missing without trying to auto-generate it.

### Git Config Strategy

The `.gitconfig` becomes a static file symlinked to `~/.gitconfig`. Any settings that require commands (like `core.excludesfile` with an expanded path) go in `post_link`. This replaces the current approach of building gitconfig entirely via `git config --global` commands.

## Constraints

- macOS only (Apple Silicon assumed, homebrew at `/opt/homebrew`)
- Go 1.22+
- No network access required after initial bootstrap (except brew operations)
- All module configs committed to repo — no secrets in the repo
- Conditional linking not supported (simplicity; revisit if multi-machine support is added)

## Non-Goals

- Multi-machine/OS support (macOS only for now)
- Secret management (SSH keys generated but not stored in repo)
- Automatic sync/pull from remote (user runs git manually)
- Plugin system beyond module directories
- `--quiet` / `--verbose` flags (keep output simple: show what was done, one line per action)

## Acceptance Criteria

- [ ] `dot` interactive mode shows all modules with state, allows multi-select setup
- [ ] `dot link` creates correct symlinks for all declared links
- [ ] `dot unlink` removes symlinks cleanly
- [ ] `dot install` installs all brew deps and cask apps
- [ ] `dot doctor` reports all issues grouped by module with fix descriptions
- [ ] `dot doctor --fix` resolves all fixable issues automatically
- [ ] `dot status` shows clear overview of module states
- [ ] `dot init <name>` scaffolds new module directory
- [ ] Adding a new tool = create module dir + module.toml + config files (no other changes needed)
- [ ] Existing configs (git, zsh, vim, homebrew, raycast) migrated to new module structure
- [ ] New modules added: ghostty, claude, tmux, apps
- [ ] bootstrap.sh works on a fresh macOS machine
- [ ] Backup existing files before replacing with symlinks
- [ ] Zsh module uses conf.d/ directory symlink — new .zsh files auto-load
- [ ] CLAUDE.md files at repo root, cmd/dot/, internal/, modules/
- [ ] README.md with human-facing documentation
