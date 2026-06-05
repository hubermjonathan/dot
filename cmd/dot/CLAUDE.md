# cmd/dot — CLI commands

One Cobra subcommand per file. Root command lives in `main.go` and delegates to `runInteractive()` when no subcommand is supplied.

## Files

| File | Command | Notes |
|------|---------|-------|
| `main.go` | `rootCmd` | Wires Cobra, owns persistent `-v` / `--verbose` flag, exits `2` on error |
| `log.go` | (helpers) | Shared output formatters: `modHeader`, `result`, `resultErr`, `runStep`, status icons |
| `interactive.go` | `dot` (no subcommand) | TUI picker → install + link selected |
| `link.go` | `dot link` | Owns shared helpers (`expandHome`, `getModules`, `getRepoRoot`) |
| `unlink.go` | `dot unlink` | Removes only entries that are actually symlinks |
| `install.go` | `dot install` | brew + cask + `provision` |
| `doctor.go` | `dot doctor [--fix]` | Walks all modules; `--fix` invokes `Issue.FixAction` |
| `status.go` | `dot status [--diff]` | Aggregates link state; `--diff` runs `diff -u` for diverged files |

## Adding a new command

1. Create `cmd/dot/<name>.go`.
2. Declare `var <name>Cmd = &cobra.Command{...}` and register in `func init() { rootCmd.AddCommand(<name>Cmd) }`.
3. Implement `run<Name>(cmd *cobra.Command, args []string) error`.
4. Resolve modules with `getModules(args)` (empty filter = all modules).
5. Expand any `~` paths via `expandHome` (or `pathutil.ExpandHome` in `internal/`).

## Conventions

- Print progress to `stdout`, errors to `stderr`. Use the helpers in `log.go`: `modHeader(name)` per module, `runStep(label, doneStatus, fn)` for any subprocess (or list of them) wrapped in a spinner — `fn` returns `[]error`, single-error callers wrap with `errSlice` (defined in `install.go`). `result(icon, msg)` / `resultErr(msg)` for plain non-spinner outcomes (used by symlink ops in `link.go`).
- `internal/ui.Step` owns spinner rendering, the captured stdout/stderr buffer, and the elapsed timer. Failed steps dump the buffer; successful steps dump only when `verbose` is true. Non-TTY runs auto-degrade to plain status lines.
- Collect failures, return `fmt.Errorf("%d operation(s) failed", n)` at end — Cobra surfaces it and `main.go` exits `2`.
- Never panic on a malformed module — log and continue.
- Repo root resolved via `git rev-parse --show-toplevel`, with a walk-up fallback for non-git checkouts.
- Module list is sorted by `[links]` source key before iteration so output is deterministic.

## Gotchas

- `interactive.go` is the root handler — it shells out to `runInstall` then `runLink`, so install errors are warned but link still runs.
- Shared helpers (`expandHome`, `getModules`, `getRepoRoot`) live in `link.go`. Don't duplicate.
- `dot doctor` exits `1` whenever any issue remains — even without `--fix` — so CI can fail on drift.
