#!/usr/bin/env bash
# Claude Code status line command
# Reads session JSON from stdin and outputs a formatted status line.

input=$(head -c 65536)

# worktree: name from worktree field if present
cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
worktree=$(echo "$input" | jq -r '.worktree.name // ""')

# cwd: if on worktree show parent repo path from ~, otherwise show repo-relative path
if [ -n "$worktree" ] && [ -n "$cwd" ]; then
  # worktree path like .../mono-repo-apps/.claude/worktrees/CONNECT-123-foo
  # extract the repo path above .claude/worktrees
  parent_repo=$(echo "$cwd" | sed 's|/\.claude/worktrees/.*||')
  if [[ "$parent_repo" == "$HOME"* ]]; then
    cwd_display="~${parent_repo#$HOME}"
  else
    cwd_display="$parent_repo"
  fi
elif [ -n "$cwd" ]; then
  if [[ "$cwd" == "$HOME"* ]]; then
    cwd_display="~${cwd#$HOME}"
  else
    cwd_display="$cwd"
  fi
else
  cwd_display=""
fi

# branch: git branch from cwd, falling back to worktree.branch from JSON
branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
if [ -z "$branch" ]; then
  branch=$(echo "$input" | jq -r '.worktree.branch // ""')
fi

# model: map ARN/name to short name
model_raw=$(echo "$input" | jq -r '.model.id // .model.display_name // ""')
case "$model_raw" in
  *yoyhj0injypc*|*opus*|*Opus*) model="Opus" ;;
  *7o4asxwz6fc7*|*sonnet*|*Sonnet*) model="Sonnet" ;;
  *bxi2s9x695ho*|*haiku*|*Haiku*) model="Haiku" ;;
  "") model="" ;;
  *) model="$model_raw" ;;
esac

# effort: not in statusline JSON, read from settings
effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
if [ "$effort" = "null" ]; then effort=""; fi

# context: used percentage (may be null early in session)
ctx_used=$(echo "$input" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
if [ "$ctx_used" = "null" ] || [ "$ctx_used" = "" ]; then ctx_used=""; fi

# session name
session_name=$(echo "$input" | jq -r '.session_name // empty' 2>/dev/null)
if [ "$session_name" = "null" ]; then session_name=""; fi

# dirty: check for uncommitted changes
dirty=""
if [ -n "$cwd" ]; then
  if ! git -C "$cwd" --no-optional-locks diff --quiet HEAD 2>/dev/null || \
     [ -n "$(git -C "$cwd" --no-optional-locks ls-files --others --exclude-standard 2>/dev/null | head -1)" ]; then
    dirty="*"
  fi
fi

# pr number: from gh if branch is pushed
pr_num=""
if [ -n "$cwd" ] && [ -n "$branch" ]; then
  pr_num=$(git -C "$cwd" --no-optional-locks config --local --get "branch.${branch}.pr" 2>/dev/null)
  if [ -z "$pr_num" ]; then
    pr_num=$(timeout 2 gh pr view --json number -q .number 2>/dev/null || true)
    if [ -n "$pr_num" ]; then
      git -C "$cwd" config --local "branch.${branch}.pr" "$pr_num" 2>/dev/null || true
    fi
  fi
fi

# jira ticket: extract from branch name (e.g. CONNECT-1234-fix-thing)
jira=""
if [ -n "$branch" ]; then
  jira=$(echo "$branch" | grep -oE '(^|/)[A-Z]+-[0-9]+' | head -1 | sed 's|^/||')
fi

# --- Colors (Dracula) ---
C_CWD="\033[38;2;189;147;249m"    # purple
C_WT="\033[38;2;255;121;198m"     # pink
C_BRANCH="\033[38;2;80;250;123m"  # green
C_PR="\033[38;2;241;250;140m"     # yellow
C_JIRA="\033[38;2;139;233;253m"   # cyan
C_MODEL="\033[38;2;248;248;242m"  # foreground
C_EFFORT="\033[38;2;255;184;108m" # orange
C_CTX="\033[38;2;80;250;123m"     # green
C_PIPE="\033[38;2;98;114;164m"    # comment gray
C_RESET="\033[0m"

# --- Build output ---
# Line 1: cwd [worktree] (branch) (#PR) (TICKET)
line1="${C_CWD}${cwd_display}${C_RESET}"
if [ -n "$worktree" ]; then
  line1+=" ${C_WT}[${worktree}]${C_RESET}"
fi
if [ -n "$branch" ]; then
  line1+=" ${C_BRANCH}(${dirty:+$dirty }${branch})${C_RESET}"
fi
if [ -n "$pr_num" ]; then
  line1+=" ${C_PR}(#${pr_num})${C_RESET}"
fi
if [ -n "$jira" ]; then
  line1+=" ${C_JIRA}(${jira})${C_RESET}"
fi

# Line 2: model | effort | ctx%
line2_parts=()
if [ -n "$model" ]; then
  line2_parts+=("${C_MODEL}${model}${C_RESET}")
fi
if [ -n "$effort" ]; then
  line2_parts+=("${C_EFFORT}${effort}${C_RESET}")
fi
if [ -n "$ctx_used" ]; then
  ctx_int=$(printf '%.0f' "$ctx_used")
  if [ "$ctx_int" -ge 80 ]; then
    ctx_color="\033[38;2;255;85;85m"      # red
  elif [ "$ctx_int" -ge 60 ]; then
    ctx_color="\033[38;2;255;184;108m"    # orange
  elif [ "$ctx_int" -ge 40 ]; then
    ctx_color="\033[38;2;241;250;140m"    # yellow
  else
    ctx_color="${C_CTX}"                   # green
  fi
  line2_parts+=("${ctx_color}${ctx_int}%${C_RESET}")
fi
if [ -n "$session_name" ]; then
  line2_parts+=("${C_PIPE}${session_name}${C_RESET}")
fi

line2=""
for i in "${!line2_parts[@]}"; do
  if [ "$i" -gt 0 ]; then
    line2+="${C_PIPE} | ${C_RESET}"
  fi
  line2+="${line2_parts[$i]}"
done

printf '%b\n%b' "$line1" "$line2"
