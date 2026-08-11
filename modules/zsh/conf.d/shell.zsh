# path
export PATH="$HOME/.local/bin:$PATH"

# prompt
function git_branch() {
  branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ $branch == "" ]]; then
    echo " "
  else
    # dirty marker matches the claude status line: * for tracked or untracked changes
    if [[ -n $(git --no-optional-locks status --porcelain 2>/dev/null | head -1) ]]; then
      echo " ($branch*) "
    else
      echo " ($branch) "
    fi
  fi
}
setopt prompt_subst
PROMPT='%~$(git_branch)%F{40}-->%f '

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
