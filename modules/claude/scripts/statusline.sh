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

# cwd display
if [ -n "$worktree" ] && [ -n "$cwd" ]; then
  parent_repo=$(echo "$cwd" | sed 's|/\.claude/worktrees/.*||')
  cwd_display=$(tildify "$parent_repo")
elif [ -n "$cwd" ]; then
  cwd_display=$(tildify "$cwd")
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

# settings drift: how many repo-required keys are missing/different on this machine
drift=""
if [ -x ~/.claude/scripts/check-settings.sh ] && [ -f ~/.claude/settings.repo.json ]; then
  drift=$(bash ~/.claude/scripts/check-settings.sh 2>/dev/null || echo 0)
  if [ "$drift" = "0" ]; then drift=""; fi
fi

# untracked: how many machine settings leaves are absent from both repo and work files
untracked=""
if [ -x ~/.claude/scripts/check-untracked.sh ] && [ -f ~/.claude/settings.json ]; then
  untracked=$(bash ~/.claude/scripts/check-untracked.sh 2>/dev/null || echo 0)
  if [ "$untracked" = "0" ]; then untracked=""; fi
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
C_DRIFT="$C_RED"
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

# --- Build output ---
line1_parts=()
if [ -n "$cwd_display" ]; then
  line1_parts+=("${C_CWD}📁 ${cwd_display}${C_RESET}")
fi
if [ -n "$worktree" ]; then
  line1_parts+=("${C_WT}🌴 ${worktree}${C_RESET}")
fi
if [ -n "$branch" ]; then
  line1_parts+=("${C_BRANCH}🌿 ${branch}${dirty:+ (*)}${C_RESET}")
fi

line1=""
for i in "${!line1_parts[@]}"; do
  if [ "$i" -gt 0 ]; then
    line1+="${C_PIPE} › ${C_RESET}"
  fi
  line1+="${line1_parts[$i]}"
done

line2_parts=()
if [ -n "$model" ]; then
  model_lc=$(echo "$model" | tr '[:upper:]' '[:lower:]')
  if [ "$model_family" = "fable" ] && [ "$effort" = "max" ]; then
    # rainbow runs continuously across "model (effort)"
    line2_parts+=("$(rainbow "$model_lc ($effort)")")
  elif [ "$model_family" = "fable" ]; then
    line2_parts+=("$(rainbow "$model_lc")${effort:+${C_FG} (${effort})${C_RESET}}")
  else
    line2_parts+=("${C_FG}${model_lc}${effort:+ (${effort})}${C_RESET}")
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
  line2_parts+=("${C_FG}${tokens_fmt} ${label}${C_RESET}")
fi

line2=""
for i in "${!line2_parts[@]}"; do
  if [ "$i" -gt 0 ]; then
    line2+="${C_PIPE} | ${C_RESET}"
  fi
  line2+="${line2_parts[$i]}"
done

if [ -n "$drift" ]; then
  line2+="${line2:+ }${C_DRIFT}settings diverged (${drift})${C_RESET}"
fi
if [ -n "$untracked" ]; then
  line2+="${line2:+ }${C_YELLOW}untracked settings (${untracked})${C_RESET}"
fi
printf '%b\n%b' "$line1" "$line2"
