#!/usr/bin/env bash
# Claude Code status line command
# Reads session JSON from stdin and outputs a formatted status line.

input=$(head -c 65536)

# Extract all JSON values in a single jq call
eval "$(echo "$input" | jq -r '
  "cwd=" + ((.workspace.current_dir // .cwd // "") | @sh) + " " +
  "worktree=" + ((.worktree.name // "") | @sh) + " " +
  "model_raw=" + ((.model.id // .model.display_name // "") | @sh) + " " +
  "ctx_used=" + ((.context_window.used_percentage // "") | tostring | @sh) + " " +
  "cost_usd=" + ((.cost.total_cost_usd // "") | tostring | @sh) + " " +
  "wt_branch=" + ((.worktree.branch // "") | @sh) + " " +
  "transcript_path=" + ((.transcript_path // "") | @sh)
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

# effort
effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
if [ "$effort" = "null" ]; then effort=""; fi

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

# context
if [ "$ctx_used" = "null" ] || [ "$ctx_used" = "" ]; then ctx_used=""; fi

# cost
if [ "$cost_usd" = "null" ] || [ "$cost_usd" = "" ]; then cost_usd=""; fi

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
  case "$model_family" in
    haiku)  line2_parts+=("${C_GREEN}🤖 ${model_lc}${C_RESET}") ;;
    sonnet) line2_parts+=("${C_ORANGE}🤖 ${model_lc}${C_RESET}") ;;
    opus)   line2_parts+=("${C_RED}🤖 ${model_lc}${C_RESET}") ;;
    fable)  line2_parts+=("🤖 $(rainbow "$model_lc")") ;;
    *)      line2_parts+=("${C_FG}🤖 ${model_lc}${C_RESET}") ;;
  esac
fi
if [ -n "$effort" ]; then
  case "$effort" in
    low)         effort_color="$C_GREEN" ;;
    medium)      effort_color="$C_YELLOW" ;;
    high)        effort_color="$C_ORANGE" ;;
    xhigh|max)   effort_color="$C_RED" ;;
    *)           effort_color="$C_FG" ;;
  esac
  line2_parts+=("${effort_color}💪 ${effort}${C_RESET}")
fi
if [ -n "$ctx_used" ]; then
  ctx_int=$(printf '%.0f' "$ctx_used")
  if   [ "$ctx_int" -ge 80 ]; then ctx_color="$C_RED"
  elif [ "$ctx_int" -ge 60 ]; then ctx_color="$C_ORANGE"
  elif [ "$ctx_int" -ge 40 ]; then ctx_color="$C_YELLOW"
  else                             ctx_color="$C_GREEN"
  fi
  line2_parts+=("${ctx_color}🧠 ${ctx_int}%${C_RESET}")
fi
if [ -n "$cost_usd" ]; then
  cost_fmt=$(printf '$%.2f' "$cost_usd")
  cost_cents=$(printf '%.0f' "$(echo "$cost_usd * 100" | bc -l 2>/dev/null || echo 0)")
  if   [ "$cost_cents" -ge 2500 ]; then cost_color="$C_RED"
  elif [ "$cost_cents" -ge 1000 ]; then cost_color="$C_ORANGE"
  elif [ "$cost_cents" -ge 200 ];  then cost_color="$C_YELLOW"
  else                                  cost_color="$C_GREEN"
  fi
  line2_parts+=("${cost_color}💵 ${cost_fmt}${C_RESET}")
fi
# water: cumulative tokens from transcript * (60/10000)*(0.000264172/1) gal
if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
  total_tokens=$(jq -s '
    [.[] | .message.usage // empty
      | (.input_tokens // 0)
      + (.output_tokens // 0)
      + (.cache_creation_input_tokens // 0)
      + (.cache_read_input_tokens // 0) * 0.3
    ] | add // 0 | round
  ' "$transcript_path" 2>/dev/null)
  if [ -n "$total_tokens" ] && [ "$total_tokens" != "0" ]; then
    water_gal=$(echo "$total_tokens * (60/10000) * (0.000264172/1)" | bc -l 2>/dev/null)
    water_fmt=$(printf '%.2f' "${water_gal:-0}")
    water_int=$(printf '%.0f' "${water_gal:-0}")
    if   [ "$water_int" -ge 15 ]; then water_color="$C_RED"
    elif [ "$water_int" -ge 5 ];  then water_color="$C_ORANGE"
    elif [ "$water_int" -ge 1 ];  then water_color="$C_YELLOW"
    else                               water_color="$C_GREEN"
    fi
    if [ "$water_fmt" = "1.00" ]; then
      line2_parts+=("${water_color}💧 ${water_fmt} gal${C_RESET}")
    else
      line2_parts+=("${water_color}💧 ${water_fmt} gals${C_RESET}")
    fi
  fi
fi

line2=""
for i in "${!line2_parts[@]}"; do
  if [ "$i" -gt 0 ]; then
    line2+="${C_PIPE} | ${C_RESET}"
  fi
  line2+="${line2_parts[$i]}"
done

line2_plain=$(printf '%b' "$line2" | sed -E $'s/\x1b\\[[0-9;]*m//g')
line2_width=$(printf '%s' "$line2_plain" | python3 -c 'import sys,unicodedata; s=sys.stdin.read(); w=sum(2 if unicodedata.east_asian_width(c) in ("W","F") else 0 if unicodedata.category(c).startswith("M") or c=="‍" or 0xFE00<=ord(c)<=0xFE0F else 1 for c in s); print(w)' 2>/dev/null || printf '%s' "$line2_plain" | awk '{print length}')
hbar=$(printf -- '─%.0s' $(seq 1 $((${line2_width:-1} + 2))))
top_border="${C_PIPE}┌${hbar}┐${C_RESET}"
bot_border="${C_PIPE}└${hbar}┘${C_RESET}"
line2_boxed="${C_PIPE}│${C_RESET} ${line2} ${C_PIPE}│${C_RESET}"
if [ -n "$drift" ]; then
  line2_boxed+=" ${C_DRIFT}🆘 settings diverged (${drift})${C_RESET}"
fi
if [ -n "$untracked" ]; then
  line2_boxed+=" ${C_YELLOW}📥 untracked settings (${untracked})${C_RESET}"
fi
printf '%b\n%b\n%b\n%b' "$line1" "$top_border" "$line2_boxed" "$bot_border"
