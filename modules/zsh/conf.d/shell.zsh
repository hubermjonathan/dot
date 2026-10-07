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
  [[ -n $CODING_AGENT ]] && return
  emulate -L zsh
  ls -a
}

# clear
function cl() {
  clear
  ls -a
}

# delete scratch dirs
function rmscratch() {
  local -a dirs
  dirs=(${(f)"$(find "${@:-$HOME}" \( -path "$HOME/Library" -o -name node_modules -o -name .git \) -prune -o -type d -name .scratch -prune -print 2>/dev/null)"})
  (( ${#dirs} )) || { echo "no .scratch dirs"; return 0 }
  du -shc "${dirs[@]}" | sed "s#$HOME#~#"
  local reply
  read "reply?delete ${#dirs} dirs? [y/N] "
  [[ $reply == [yY] ]] || return 1
  rm -rf -- "${dirs[@]}" && echo "deleted ${#dirs} dirs"
}

# aliases
alias ..="cd .."
alias rr="reset"
alias pbc="pbcopy"
alias c="claude"
