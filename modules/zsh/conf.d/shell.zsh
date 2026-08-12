# path
export PATH="$HOME/.local/bin:$PATH"

# prompt
function git_dir() {
  local dir=$PWD
  if [[ $dir == */.claude/worktrees/* ]]; then
    dir=${dir%%/.claude/worktrees/*}
  fi
  echo "${dir/#$HOME/~}"
}

function git_branch() {
  local label open close rest
  if [[ $PWD == */.claude/worktrees/* ]]; then
    rest=${PWD#*/.claude/worktrees/}
    label=${rest%%/*}
    open="[" close="]"
  else
    label=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ $label == "" ]]; then
      echo " "
      return
    fi
    open="(" close=")"
  fi
  if [[ -n $(git --no-optional-locks status --porcelain 2>/dev/null | head -1) ]]; then
    echo " ${open}${label} *${close} "
  else
    echo " ${open}${label}${close} "
  fi
}
setopt prompt_subst
PROMPT='$(git_dir)$(git_branch)%F{40}-->%f '

# tab renaming
tab() {
  echo -ne "\033]0;$*\007"
}

# cd ls
function chpwd() {
  emulate -L zsh
  ls -a
}

# clear
function cl() {
  clear
  ls -a
}

# aliases
alias ..="cd .."
alias rr="reset"
alias pbc="pbcopy"
alias c="claude agents"
