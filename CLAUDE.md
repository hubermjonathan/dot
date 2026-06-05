# dot — Claude guide

Personal macOS dotfiles managed by `dot`, a Go CLI (Cobra-based) that walks `modules/`, creates symlinks, runs Homebrew installs, and executes per-module setup hooks. Modules are self-describing TOML files with their config payload alongside.

## Build / test

    ./scripts/build.sh   # writes ./bin/dot
    go test ./...

## Repo layout

- `bootstrap.sh` — first-run installer (Xcode CLT → Homebrew → Go → build → `dot install` → `dot link`).
- `cmd/dot/` — Cobra subcommands, one file per command. See `cmd/dot/CLAUDE.md`.
- `internal/` — discovery, linker, installer, doctor, TUI. See `internal/CLAUDE.md`.
- `modules/` — pluggable config modules. See `modules/CLAUDE.md`.
- `bin/dot` — committed binary so `bootstrap.sh` can run before Go is installed (rebuilt and re-committed on changes that touch the CLI).
- `scripts/build.sh` — `go build -o bin/dot ./cmd/dot`.

## Commands (CLI surface)

| Command | Purpose |
|---------|---------|
| `dot` | Bubble Tea picker → `install` then `link` for selected modules |
| `dot link [mod...]` | Create symlinks, run `setup.post_link` |
| `dot unlink [mod...]` | Remove symlinks |
| `dot install [mod...]` | brew formulae + casks + `setup.provision` |
| `dot doctor [--fix]` | Run symlink + `[health]` checks; optionally repair |
| `dot status [--diff]` | Per-module link state; `--diff` shows divergence vs repo |

Module args optional → omit to act on every module. Exit codes: `0` ok, `1` partial, `2` fatal.

Output: each subprocess step renders as a single spinner row (label + most recent line of output) via `internal/ui`. On success the row collapses to `✓ label — status (elapsed)`; on failure the captured buffer is dumped indented below the row. `-v` / `--verbose` keeps the spinner UI but always dumps the buffer at the end of every successful step. Non-TTY (pipes/CI) prints the opening label and final status line only — no redraw, no escape codes. `setup.interactive = true` modules bypass the spinner so stdin/stdout pass through directly (auth flows).

## Key invariants

- **Continue-on-error**: one module failing must not stop later modules. Commands collect failures and exit non-zero at the end.
- **Symlink direction**: source = file in repo, target = path under `~`. `~` expanded at runtime via `internal/pathutil`.
- **Idempotent post_link**: every command in `[setup].post_link` runs on every `dot link`. Always guard side effects (`test -f ...`, `grep -q ...`, etc.).
- **Provision is one-shot**: `[setup].provision` runs only on `dot install`. Use it for things that must not re-run (e.g. `gh auth login`).
- **Backups before replace**: `dot link` moves a pre-existing regular file to `~/.dotfiles-backup/<module>/<basename>.<hash>` before linking. `dot doctor --fix` does *not* back up — it assumes prior `dot link`.
- **Directory symlinks supported**: e.g. `zsh/conf.d` → `~/.config/zsh`. Files dropped inside are immediately live.
- **No global state in `internal/`**: dependencies passed explicitly. `expandHome` lives in `cmd/dot/` (CLI concern).
- **Docs stay in sync**: any change to the CLI surface, module schema, or layout must update `README.md` plus the relevant `CLAUDE.md` (root, `cmd/dot/`, `internal/`, `modules/`). Adding/removing a command → update both. Adding a module → update the module catalogue in `README.md` and `modules/CLAUDE.md`. Adding a TOML section or health-check kind → update `modules/CLAUDE.md` schema + cheat-sheet.

## Testing patterns

- Filesystem tests use `t.TempDir()`.
- Tests live next to the code (`internal/<pkg>/<pkg>_test.go`).
- No mocks for filesystem — use real temp dirs.

## Adding a module

    mkdir modules/mytool
    # write modules/mytool/module.toml + drop config files alongside
    dot link mytool

See `modules/CLAUDE.md` for the full schema (links, deps, apps, health, setup).
