# Dotfiles

Go CLI (`dot`) managing configs via symlinks + brew app installation.

## Build

    go build -o bin/dot ./cmd/dot

## Commit conventions

- Use conventional commits: `type: description` (max 50 chars)
- Do not add co-author lines

## Project layout

- `cmd/dot/` — CLI commands (Cobra)
- `internal/` — core packages (module, linker, installer, doctor, tui)
- `modules/` — config modules (each has module.toml + config files)

## Testing

    go test ./...

## Key patterns

- Modules discovered at runtime by walking `modules/` dir
- Symlinks point FROM repo files TO home directory targets
- `~` in module.toml is expanded at runtime
- Directory symlinks (like zsh/conf.d → ~/.config/zsh) are supported
- Continue-on-error: one module failing doesn't stop others
- Exit codes: 0=success, 1=partial failure, 2=fatal
