# dot

`README.md` is the reference for this repo. The `AGENTS.md` files hold only invariants and gotchas, and `modules/` has one.

## Key invariants

- **Keep the checkout on main**: every link points into `~/Code/dot`, so the machine runs whatever branch it has checked out. Make changes in a worktree and keep `~/Code/dot` on `main`. A worktree's own `./bin/dot link` points the links into the worktree, so run it there only with a temporary `HOME`.
- **README owns the reference**: a change to anything the README describes, such as the commands, exit codes, module schema, skips file, layout, or module table, updates `README.md` in the same commit. Point to the README from an `AGENTS.md` instead of copying it.
- **Continue-on-error**: one module failing must not stop later modules. Commands collect failures and exit non-zero at the end.

## Testing patterns

- `scripts/test.sh` runs `bin/dot` against real files: a fixture repo and a temporary `HOME`, with `brew` and `gh` stubs on `PATH`, and bare git repos as each checkout's `origin`. Run it after changing `bin/dot` or a `module.sh`.

## Where a rule goes

- `modules/agents/instructions.md` loads in every session on every machine, and this repo is public. Keep only what most sessions need there, and nothing private. A rule for the work machine goes in dot-work's `modules/work/agents/AGENTS.local.md`, and a rule for one kind of task goes in a skill.
