# dot

Personal macOS configuration managed by `dot`, a Go CLI that handles symlinks, app installation, and health checks.

## Quick Start (New Machine)

```bash
git clone https://github.com/hubermjonathan/dot
cd dot
./bootstrap.sh
```

## Usage

```bash
dot              # Interactive — pick modules to set up
dot link         # Create all symlinks
dot install      # Install all deps and apps
dot doctor       # Check health (add --fix to auto-repair)
dot status       # Show module states
dot init <name>  # Create a new module
```

## Build

```bash
go build -o bin/dot ./cmd/dot
```

## Adding a New Tool

```bash
dot init mytool
# Edit modules/mytool/module.toml — add links, deps, apps
# Drop config files in modules/mytool/
dot link mytool
```

## Zsh Config

Drop `.zsh` files in `modules/zsh/conf.d/` — they're sourced automatically on shell start. No module.toml edit needed.

## Modules

| Module | Description |
|--------|-------------|
| git | Git config + SSH key |
| zsh | Shell config (conf.d auto-discovery) |
| vim | Vim + Vundle + noir theme |
| scripts | AppleScript utilities (Format JSON, Caffeinate) |
| ghostty | Ghostty terminal |
| tmux | Terminal multiplexer |
| claude | Claude Code config |
| macos | macOS system preferences |
| apps | Standalone applications (alt-tab, bitwarden, karabiner, spotify, meetingbar) |
