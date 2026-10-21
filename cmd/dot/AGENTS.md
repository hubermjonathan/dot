# cmd/dot — CLI commands

One Cobra subcommand per file. Shared helpers live in `link.go` (`getModules`, `getRepoRoot`, `ensureSkips`) and `log.go` (output and spinners).

## Adding a new command

1. Create `cmd/dot/<name>.go`.
2. Declare `var <name>Cmd = &cobra.Command{...}` and register in `func init() { rootCmd.AddCommand(<name>Cmd) }`.
3. Implement `run<Name>(cmd *cobra.Command, args []string) error`.
4. Resolve modules with `getModules(args)` (empty filter = all modules). It already drops what `~/.dot-skips` skips, so commands don't check skips themselves.
5. Expand any `~` paths with `pathutil.ExpandHome`.

## Conventions

- Print progress to `stdout` and errors to `stderr` through the helpers in `log.go`. Run each subprocess through `runStep`, or `runScriptsStep` for a `post_link` or `provision` list, so it gets the spinner, the `-v` replay, and interactive passthrough.
- Return `fmt.Errorf("%d operation(s) failed", n)` after the last module, as `link.go` does.
- `getRepoRoot` finds the repo from the binary's own path, `<repo>/bin/dot`, not from the working directory, so the `dot` on `PATH` acts on `~/Code/dot`.
- `module.Discover` sorts modules by name, and each command walks a module's links sorted by source, so output is deterministic.

## Gotchas

- `interactive.go` is the root handler. It calls `runInstall` and then `runLink` in the same process, so an install error prints a warning and link still runs.
