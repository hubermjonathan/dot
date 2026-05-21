# modules — Config Modules

Each subdirectory is a module. Must contain `module.toml`.

## Adding a new module

1. `dot init <name>` (or manually create dir + module.toml)
2. Add config files to the directory
3. Declare symlinks in `[links]`: source (relative) = target (absolute with ~)
4. Add brew deps in `[deps]`, cask apps in `[apps]`
5. Run `dot link <name>` to activate

## module.toml sections

- `[module]` — name, description
- `[links]` — file/dir symlink mappings
- `[deps]` — brew formulae
- `[apps]` — brew casks
- `[health]` — extra checks (file_exists, dir_exists, command_succeeds)
- `[setup]` — post_link (idempotent, runs on link), provision (one-time, runs on install), interactive (bool, opts setup commands into stdin/stdout/stderr passthrough; default off)

## Directory symlinks

Use for auto-discovery (e.g., zsh/conf.d → ~/.config/zsh).
Files inside dir-linked paths don't need individual [links] entries.
Drop a new file in the directory and it's live on next shell session.

## Gotchas

- post_link commands MUST be idempotent (safe to re-run)
- provision commands only run via `dot install`, never `dot doctor --fix`
- Health checks with `~` are expanded at runtime
