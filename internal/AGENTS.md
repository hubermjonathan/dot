# internal — core packages

Nothing here imports Cobra or reads a flag. `cmd/dot/` wires the packages together.

## Conventions

- **No global state**: pass dependencies through arguments.
- **New linker states**: a new `linker.Status` needs a case in `doctor.statusName` and in both switches in `cmd/dot/status.go`. Without them, `dot doctor` prints it as `unknown`, and `dot status` leaves it out of the module state.
- **Health check kinds** live in `doctor.ParseCheck`. A new kind goes there and in the README's list of kinds.
