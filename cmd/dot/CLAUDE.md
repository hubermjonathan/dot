# cmd/dot — CLI Commands

Each file = one Cobra command. Pattern:

1. Declare `var xxxCmd = &cobra.Command{...}`
2. Register in `func init() { rootCmd.AddCommand(xxxCmd) }`
3. Implement `runXxx(cmd, args) error`

## Adding a new command

1. Create `cmd/dot/mycommand.go`
2. Follow the pattern above
3. Use `getModules(args)` to resolve module filter
4. Use `expandHome()` for `~` paths

## Gotchas

- `init_cmd.go` not `init.go` (avoids Go's init() function conflict)
- `interactive.go` is the root command handler (no subcommand)
- Exit codes: 0=success, 1=partial failure, 2=fatal
- Shared helpers (expandHome, getModules, getRepoRoot) live in link.go
