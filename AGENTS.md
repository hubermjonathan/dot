# dot

`README.md` is the reference for this repo: how to install, build, and test, the commands and their exit codes, the module schema, the skips file, and the module table. The `AGENTS.md` files hold only what the README doesn't: invariants and gotchas. `cmd/dot/`, `internal/`, and `modules/` each have one.

## Key invariants

- **Continue-on-error**: one module failing must not stop later modules. Commands collect failures and exit non-zero at the end.
- **README owns the reference**: a change to the CLI surface, the module schema, the repo layout, or the module list updates `README.md` in the same commit. Don't copy a README fact into an `AGENTS.md`. Point to it.

## Testing patterns

- Filesystem tests use `t.TempDir()`.
- Tests live next to the code (`internal/<pkg>/<pkg>_test.go`).
- No mocks for filesystem — use real temp dirs.
