#!/usr/bin/env bash
# Moves a leaf from ~/.claude/settings.json into either settings.work.json
# or settings.repo.json, then re-runs merge-settings.sh so the canonical
# settings.json regenerates from the layered sources.
#
# Usage:
#   sort-setting.sh <target> <jq-path> [...]
#
# Arguments:
#   <target>     "work" or "repo"
#   <jq-path>    Dot/bracket path to the leaf, e.g. ".env.AWS_PROFILE"
#                or '.permissions.allow'. Multiple paths may be passed
#                to move several leaves at once.
#
# Behavior:
#   - Scalar leaves: target value set; original deleted from settings.json.
#   - Array leaves: target array gets the union; settings.json original is
#                   left alone (the merge will dedupe back together).
#   - Repo target: writes to ~/.claude/settings.repo.json, which is a
#                  symlink into the dot repo — change is versioned.
#
# The script refuses paths that don't currently resolve in settings.json
# so a typo cannot silently no-op.

set -euo pipefail

usage() {
  echo "usage: sort-setting.sh <work|repo> <jq-path> [<jq-path>...]" >&2
  exit 2
}

[ $# -lt 2 ] && usage

target="$1"; shift
case "$target" in
  work) target_file="${CLAUDE_WORK_SETTINGS:-$HOME/.claude/settings.work.json}" ;;
  repo) target_file="${CLAUDE_REPO_SETTINGS:-$HOME/.claude/settings.repo.json}" ;;
  *) usage ;;
esac

machine_settings="${CLAUDE_MACHINE_SETTINGS:-$HOME/.claude/settings.json}"
merge_script="${CLAUDE_MERGE_SCRIPT:-$HOME/.claude/scripts/merge-settings.sh}"

[ -f "$machine_settings" ] || { echo "sort-setting: missing $machine_settings" >&2; exit 1; }
[ -f "$target_file" ]      || echo '{}' > "$target_file"

# Resolve symlink so we can write through atomically (mv replaces link otherwise).
target_real=$(readlink "$target_file" 2>/dev/null || echo "$target_file")
[ -f "$target_real" ] || target_real="$target_file"

for raw_path in "$@"; do
  # Normalize: accept both ".env.FOO" and "env.FOO".
  jq_path="${raw_path#.}"
  jq_path=".${jq_path}"

  # Verify the path exists in settings.json.
  exists=$(jq --arg ok "ok" "if (try ($jq_path) // \"__ABSENT__\") == \"__ABSENT__\" then \"\" else \$ok end" "$machine_settings")
  if [ -z "$exists" ]; then
    echo "sort-setting: path not found in $machine_settings: $jq_path" >&2
    exit 1
  fi

  value_kind=$(jq -r "$jq_path | type" "$machine_settings")

  # Write into target file.
  tmp=$(mktemp "${TMPDIR:-/tmp}/claude-sort.XXXXXX")
  trap 'rm -f "$tmp"' EXIT
  if [ "$value_kind" = "array" ]; then
    jq "(($jq_path) // []) as \$existing
        | $jq_path = ((\$existing + (input | $jq_path)) | unique)" \
        "$target_real" "$machine_settings" > "$tmp"
  else
    jq "$jq_path = (input | $jq_path)" "$target_real" "$machine_settings" > "$tmp"
  fi
  mv "$tmp" "$target_real"
  trap - EXIT

  # Strip from settings.json so merge can repopulate it cleanly. Arrays
  # included — merge will union them back from the target file.
  tmp2=$(mktemp "${TMPDIR:-/tmp}/claude-sort.XXXXXX")
  trap 'rm -f "$tmp2"' EXIT
  jq "del($jq_path)" "$machine_settings" > "$tmp2"
  mv "$tmp2" "$machine_settings"
  trap - EXIT

  echo "sort-setting: $jq_path → $target ($value_kind)"
done

# Re-merge so settings.json is canonical again.
if [ -x "$merge_script" ]; then
  bash "$merge_script"
else
  echo "sort-setting: warning — merge script not executable: $merge_script" >&2
fi
