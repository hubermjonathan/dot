# internal — core packages

Pure logic, no CLI concerns. Each package exports a small surface; `cmd/dot/` wires them together.

## Packages

| Package | Responsibility |
|---------|---------------|
| `module/` | `Module` struct, TOML parsing (`toml.go`), filesystem discovery (`discover.go`) |
| `linker/` | Symlink create / remove / verify, with backup-before-replace for regular files |
| `installer/` | `brew install` and `brew install --cask`, executes `post_link` and `provision` script lists |
| `doctor/` | Aggregates symlink + `[health]` issues into `Issue`s, attaches optional `FixAction` |
| `tui/` | Bubble Tea picker — list of modules with selection state |
| `pathutil/` | `ExpandHome` (`~` → `$HOME`) — used by both `cmd/dot/` and `internal/` |

## Conventions

- **No global state** — pass dependencies through arguments.
- **Functions return errors** — the caller decides whether to continue or abort. The CLI relies on this to keep going across modules.
- **Tests use `t.TempDir()`** for filesystem isolation. No mocks; real symlinks against real temp dirs.
- **Linker statuses are exhaustive** — `StatusOK`, `StatusBroken`, `StatusMissing`, `StatusWrongTarget`, `StatusNotSymlink`. Add a new state only when an existing one cannot represent the case.
- **Health check kinds** are limited to three: `file_exists`, `dir_exists`, `command_succeeds`. New kinds go in `doctor.ParseCheck`.
- **`expandHome` lives in `cmd/dot/`** — it's a CLI concern. Internal packages take already-expanded paths or use `pathutil.ExpandHome` directly.

## Testing

    go test ./internal/...

## Adding a package

1. `internal/<pkg>/<pkg>.go` with a tight exported API.
2. `internal/<pkg>/<pkg>_test.go` next to it.
3. Wire it into `cmd/dot/` — no `init()` magic, no service locators.
