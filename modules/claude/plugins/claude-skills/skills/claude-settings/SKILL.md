---
name: claude-settings
description: Inspect and reorganize the layered Claude Code settings files at ~/.claude/{settings.json, settings.work.json, settings.repo.json}. Use when the user asks "what settings are diverged", "what settings are untracked", "move this setting to work", "move this setting to repo", "sort this setting", or any variant about Claude's own settings hierarchy. Also triggers when the statusline shows 🆘 settings diverged or 📥 untracked settings.
---

# Claude settings curator

Three settings files form one effective config:

| File | Role |
|------|------|
| `~/.claude/settings.repo.json` | Versioned (symlink into `dot/modules/claude/settings.repo.json`). Required everywhere. |
| `~/.claude/settings.work.json` | Machine-local, work tooling. Not versioned. |
| `~/.claude/settings.json` | What Claude Code actually reads. Produced by `merge-settings.sh` from `machine ⊕ work ⊕ repo` (right wins). |

Two failure modes:

- **Diverged** — repo says X, machine says Y (or missing). 🆘
- **Untracked** — machine has a leaf neither work nor repo declares. 📥

Both are statusline indicators. This skill turns the indicators into actions.

## Helper scripts

All live in `~/.claude/scripts/` (symlinked from `dot/modules/claude/scripts/`):

| Script | Purpose |
|--------|---------|
| `check-settings.sh` | Returns int — number of diverged repo leaves. |
| `check-untracked.sh` | Returns int — number of untracked machine leaves. |
| `list-diverged.sh` | Returns JSON array — `{path, repo_value, machine_value, kind}` per diverged leaf. |
| `list-untracked.sh` | Returns JSON array — `{path, value, kind}` per untracked leaf. |
| `sort-setting.sh <work\|repo> <jq-path>...` | Move leaves from `settings.json` into target file, then re-merge. |
| `merge-settings.sh` | Re-runs the merge. Idempotent. |
| `reconcile-cli.sh` | Diffs `settings.json` vs a `settings.cli.snapshot.json` snapshot, prunes vanished keys from `settings.work.json`. Run AFTER an external CLI (e.g. `gh ou doctor -a`) that overwrites `settings.json`, BEFORE `merge-settings.sh`. Bootstraps the snapshot on first run. |

## Workflow

### 1. Answer "what's diverged?" / "what's untracked?"

```bash
bash ~/.claude/scripts/list-diverged.sh    # repo says X but machine doesn't
bash ~/.claude/scripts/list-untracked.sh   # machine has X but neither layer declares it
```

Render the JSON for the user as a table — path, current value, recommendation. **Do not** mutate without confirmation.

For each untracked leaf, propose a destination based on the value's nature:

- Personal/secret/work-account-specific (AWS profiles, telemetry endpoints, work plugins) → `work`
- General preference, applies on every machine the user owns (caveman config, model preference, hooks they want everywhere) → `repo`

If unclear, ask the user. Do not guess.

### 2. Answer "what's diverged from the source of truth"

`list-diverged.sh` covers it. For each entry:
- `kind: "missing"` → repo declares the leaf but machine has none → run `merge-settings.sh` to apply.
- `kind: "scalar_mismatch"` → machine value differs from repo. Either machine value is stale (run merge — repo wins) **or** the machine value is intentional and should be in `settings.work.json` instead. Ask the user.
- `kind: "array_subset_missing"` → repo has elements machine lacks. Merge will fix it.

### 3. Answer "sort this setting to work" / "...to repo"

Identify the path. Then:

```bash
bash ~/.claude/scripts/sort-setting.sh work .env.AWS_PROFILE
bash ~/.claude/scripts/sort-setting.sh repo .effortLevel
bash ~/.claude/scripts/sort-setting.sh work '.permissions.allow'  # arrays OK
```

Multiple paths in one call:
```bash
bash ~/.claude/scripts/sort-setting.sh work .env.AWS_PROFILE .env.AWS_REGION
```

After running, re-check:
```bash
bash ~/.claude/scripts/check-untracked.sh   # should drop
bash ~/.claude/scripts/check-settings.sh    # should still be 0
```

### 4. Apply repo changes are versioned

`~/.claude/settings.repo.json` is a symlink. Writing through it dirties `dot/modules/claude/settings.repo.json`. Tell the user — they will likely want to commit.

## jq path syntax

`sort-setting.sh` accepts standard jq paths:

| Setting | Path |
|---------|------|
| top-level scalar | `.effortLevel` |
| nested env var | `.env.AWS_PROFILE` |
| array | `.permissions.allow` |
| nested object — pass parent path; sort children individually | `.permissions.allow`, not `.permissions` |

Don't pass an object path — `sort-setting.sh` enforces leaves only.

## Edge cases

- **Array splitting**: if half the elements belong in work and half in repo, call `sort-setting.sh` once per target with the full path; then manually trim the source-of-truth file to remove the now-misplaced half. The script does **not** support per-element splitting.
- **Renaming/restructuring**: out of scope — edit the files directly.
- **Conflict where machine has different value than both work and repo**: that's an "untracked" entry from `list-untracked.sh`. Either move the divergent value into work (overrides repo for this machine) or accept repo's value (re-merge, repo wins).

## Verification after any mutation

```bash
diff <(jq -S . ~/.claude/settings.json) <(jq -S . ~/.claude/settings.json.before)
```

Or — simpler — re-run `check-*.sh`. Both should return `0` when the layered files fully describe the effective config.
