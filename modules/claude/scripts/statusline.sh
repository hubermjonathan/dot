#!/usr/bin/env bash
# Claude Code status line command
# Reads session JSON from stdin and outputs a formatted status line.

input=$(head -c 65536)

# Extract all JSON values in a single jq call
eval "$(echo "$input" | jq -r '
  "cwd=" + ((.workspace.current_dir // .cwd // "") | @sh) + " " +
  "worktree=" + ((.worktree.name // "") | @sh) + " " +
  "model_raw=" + ((.model.id // .model.display_name // "") | @sh) + " " +
  "wt_branch=" + ((.worktree.branch // "") | @sh) + " " +
  "ctx_tokens=" + ((.context_window.total_input_tokens // "") | tostring | @sh) + " " +
  "effort=" + ((.effort.level // "") | @sh)
')"

tildify() { [[ "$1" == "$HOME"* ]] && echo "~${1#$HOME}" || echo "$1"; }

# shorten_path: keep root marker + first 2 + last 2 segments, middle -> ...
# e.g. ~/Code/dot/src/main/modules/backfill/scripts -> ~/Code/dot/.../backfill/scripts
shorten_path() {
  local p="$1"
  local -a seg
  IFS='/' read -r -a seg <<< "$p"
  local begin="${seg[0]}"          # "~", "" (absolute), or first segment (relative)
  local -a after=("${seg[@]:1}")
  local m=${#after[@]}
  local body
  if [ "$m" -gt 4 ]; then
    body="${after[0]}/${after[1]}/.../${after[m-2]}/${after[m-1]}"
  elif [ "$m" -gt 0 ]; then
    local IFS='/'; body="${after[*]}"
  else
    printf '%s' "$begin"; return
  fi
  if [ -z "$begin" ]; then printf '/%s' "$body"; else printf '%s/%s' "$begin" "$body"; fi
}

# worktree: from JSON, else derive from cwd path (.claude/worktrees/<name>/...)
if [ -z "$worktree" ] && [[ "$cwd" == */.claude/worktrees/* ]]; then
  wt_rest="${cwd#*/.claude/worktrees/}"
  worktree="${wt_rest%%/*}"
fi

# cwd display: show parent repo (strip the worktree suffix), middle folders elided
if [[ "$cwd" == */.claude/worktrees/* ]]; then
  parent_repo="${cwd%%/.claude/worktrees/*}"
  cwd_display=$(shorten_path "$(tildify "$parent_repo")")
elif [ -n "$cwd" ]; then
  cwd_display=$(shorten_path "$(tildify "$cwd")")
else
  cwd_display=""
fi

# branch: git branch from cwd, falling back to worktree.branch from JSON
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
if [ -z "$branch" ]; then
  branch="$wt_branch"
fi

# model: map ARN/name to short name using ANTHROPIC_DEFAULT_*_MODEL settings
model=""
model_family=""
if [ -n "$model_raw" ]; then
  eval "$(jq -r '
    .env // {} |
    "opus_arn="    + ((.ANTHROPIC_DEFAULT_OPUS_MODEL    // "") | @sh) + " " +
    "sonnet_arn="  + ((.ANTHROPIC_DEFAULT_SONNET_MODEL  // "") | @sh) + " " +
    "haiku_arn="   + ((.ANTHROPIC_DEFAULT_HAIKU_MODEL   // "") | @sh) + " " +
    "fable_arn="   + ((.ANTHROPIC_DEFAULT_FABLE_MODEL   // "") | @sh) + " " +
    "opus_name="   + ((.ANTHROPIC_DEFAULT_OPUS_MODEL_NAME   // "Opus")   | @sh) + " " +
    "sonnet_name=" + ((.ANTHROPIC_DEFAULT_SONNET_MODEL_NAME // "Sonnet") | @sh) + " " +
    "haiku_name="  + ((.ANTHROPIC_DEFAULT_HAIKU_MODEL_NAME  // "Haiku")  | @sh) + " " +
    "fable_name="  + ((.ANTHROPIC_DEFAULT_FABLE_MODEL_NAME  // "Fable")  | @sh)
  ' ~/.claude/settings.json 2>/dev/null)"

  if   [ -n "$opus_arn" ]   && [ "$model_raw" = "$opus_arn" ];   then model="$opus_name";   model_family="opus"
  elif [ -n "$sonnet_arn" ] && [ "$model_raw" = "$sonnet_arn" ]; then model="$sonnet_name"; model_family="sonnet"
  elif [ -n "$haiku_arn" ]  && [ "$model_raw" = "$haiku_arn" ];  then model="$haiku_name";  model_family="haiku"
  elif [ -n "$fable_arn" ]  && [ "$model_raw" = "$fable_arn" ];  then model="$fable_name";  model_family="fable"
  else
    case "$model_raw" in
      *opus*|*Opus*)     model="${opus_name:-Opus}";     model_family="opus" ;;
      *sonnet*|*Sonnet*) model="${sonnet_name:-Sonnet}"; model_family="sonnet" ;;
      *haiku*|*Haiku*)   model="${haiku_name:-Haiku}";   model_family="haiku" ;;
      *fable*|*Fable*)   model="${fable_name:-Fable}";   model_family="fable" ;;
      *) model="$model_raw" ;;
    esac
  fi
fi

# effort: session value from stdin, falling back to persisted setting
if [ -z "$effort" ]; then
  effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
  if [ "$effort" = "null" ]; then effort=""; fi
fi

# settings state: ~/.claude/settings.json is a symlink into the dot repo, so
# "uncommitted" covers every way it drifts — work tooling writing keys in, an
# accidental /config change, or a keeper that still needs a commit.
settings_state=""
settings_link=$(readlink ~/.claude/settings.json 2>/dev/null)
if [ -z "$settings_link" ]; then
  settings_state="unlinked"
elif [ -n "$(git -C "$(dirname "$settings_link")" --no-optional-locks status --porcelain -- "$settings_link" 2>/dev/null)" ]; then
  settings_state="uncommitted"
fi

# dirty: single git call for tracked + untracked
dirty=""
if [ -n "$cwd" ]; then
  if [ -n "$(git -C "$cwd" --no-optional-locks status --porcelain 2>/dev/null | head -1)" ]; then
    dirty="*"
  fi
fi

# --- Colors (Dracula) ---
C_FG="\033[38;2;248;248;242m"     # foreground
C_CWD="$C_FG"
C_WT="$C_FG"
C_BRANCH="$C_FG"
C_GREEN="\033[38;2;80;250;123m"   # green
C_YELLOW="\033[38;2;241;250;140m" # yellow
C_ORANGE="\033[38;2;255;184;108m" # orange
C_RED="\033[38;2;255;85;85m"      # red
C_CYAN="\033[38;2;139;233;253m"   # cyan
C_PURPLE="\033[38;2;189;147;249m" # purple
C_PINK="\033[38;2;255;121;198m"   # pink
C_PIPE="\033[38;2;99;99;99m"      # grey39
C_RESET="\033[0m"

# rainbow: color each char of $1 with cycling Dracula palette
rainbow() {
  local text="$1"
  local -a palette=("$C_RED" "$C_ORANGE" "$C_YELLOW" "$C_GREEN" "$C_CYAN" "$C_PURPLE" "$C_PINK")
  local i=0 out="" ch
  while [ $i -lt ${#text} ]; do
    ch="${text:$i:1}"
    out+="${palette[$((i % ${#palette[@]}))]}${ch}"
    i=$((i + 1))
  done
  printf '%s%s' "$out" "$C_RESET"
}

# join_parts: join remaining args with separator $1 into $REPLY (no subshell)
join_parts() {
  local sep="$1"; shift
  REPLY=""
  local x
  for x in "$@"; do REPLY="${REPLY:+$REPLY$sep}$x"; done
}

# --- Build output ---
# line 1: dir › worktree › branch
line1_parts=()
if [ -n "$cwd_display" ]; then
  line1_parts+=("${C_CWD}📁 ${cwd_display}${C_RESET}")
fi
# on a worktree show only the worktree (with dirty marker), else the branch
if [ -n "$worktree" ]; then
  line1_parts+=("${C_WT}🌴 ${worktree}${dirty:+ (*)}${C_RESET}")
elif [ -n "$branch" ]; then
  line1_parts+=("${C_BRANCH}🌿 ${branch}${dirty:+ (*)}${C_RESET}")
fi
join_parts "${C_PIPE} › ${C_RESET}" "${line1_parts[@]}"; line1="$REPLY"

# line 2: model (effort) | tokens
line2_parts=()
if [ -n "$model" ]; then
  model_lc=$(echo "$model" | tr '[:upper:]' '[:lower:]')
  if [ "$model_family" = "fable" ] && [ "$effort" = "max" ]; then
    # rainbow runs continuously across "model (effort)"
    line2_parts+=("🤖 $(rainbow "$model_lc ($effort)")")
  elif [ "$model_family" = "fable" ]; then
    line2_parts+=("🤖 $(rainbow "$model_lc")${effort:+${C_FG} (${effort})${C_RESET}}")
  else
    line2_parts+=("${C_FG}🤖 ${model_lc}${effort:+ (${effort})}${C_RESET}")
  fi
fi
# tokens: input tokens currently in the context window, comma-grouped
if [ -n "$ctx_tokens" ] && [ "$ctx_tokens" != "null" ] && [ "$ctx_tokens" != "0" ]; then
  n="$ctx_tokens"; tokens_fmt=""
  while [ ${#n} -gt 3 ]; do
    tokens_fmt=",${n: -3}${tokens_fmt}"
    n="${n:0:${#n}-3}"
  done
  tokens_fmt="${n}${tokens_fmt}"
  label="tokens"; [ "$ctx_tokens" = "1" ] && label="token"
  warn=""; [ "$ctx_tokens" -gt 150000 ] && warn=" 🥴"
  line2_parts+=("${C_FG}🧠 ${tokens_fmt} ${label}${warn}${C_RESET}")
fi
join_parts "${C_PIPE} › ${C_RESET}" "${line2_parts[@]}"; line2="$REPLY"

# line 3: settings warning, only shown when settings.json drifts from the repo
line3=""
case "$settings_state" in
  unlinked)    line3="${C_RED}🆘 settings not linked to repo${C_RESET}" ;;
  uncommitted) line3="${C_YELLOW}📥 settings uncommitted${C_RESET}" ;;
esac

# emit: line 1 always; line 2 (model) and line 3 (warning) only when non-empty
out="$line1"
[ -n "$line2" ] && out="${out}"$'\n'"${line2}"
[ -n "$line3" ] && out="${out}"$'\n'"${line3}"
printf '%b' "$out"
