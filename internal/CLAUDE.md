# internal — Core Packages

## Packages

- `module/` — Module struct, TOML parsing, discovery
- `linker/` — Symlink operations (create, remove, verify, backup)
- `installer/` — Brew/cask installation, post_link/provision execution
- `doctor/` — Health checks, issue collection, fix execution
- `tui/` — Bubble Tea interactive picker

## Conventions

- No global state. Pass dependencies explicitly.
- Functions return errors, callers decide to continue or abort.
- Tests use `t.TempDir()` for filesystem tests.
- `expandHome` lives in cmd/dot (CLI concern), not internal.

## Testing

    go test ./internal/...

## Adding a new package

1. Create `internal/mypkg/mypkg.go`
2. Export a clean interface (functions or methods)
3. Add tests in `internal/mypkg/mypkg_test.go`
4. Wire into CLI commands in `cmd/dot/`
