# oh my zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="minimal"
DISABLE_AUTO_TITLE="true"
zstyle ":omz:update" mode auto
zstyle ":omz:update" frequency 14
plugins=()
source $ZSH/oh-my-zsh.sh

# tab renaming
tab() {
  echno -ne "\033]0;$*\007"
}

# cd ls
function chpwd() {
  emulate -L zsh
  ls -a
}

# clear
function c() {
  clear
  ls -a
}

# git
function gc() {
  git commit -m "$1"
}
function gca() {
  git commit --amend -m $1
}
function gt() {
  git tag -a $1 $2 -m $1
}
alias gs="git status"
alias gd="git diff ."
alias gsw="git switch"
alias gco="git checkout"
alias gb="git branch"
alias gbd="git branch -D"
alias gl="git log --oneline"
alias ga="git add ."
alias gp="git pull"
alias gf="git fetch"
alias gpo="git push origin"

# aliases
alias ..="cd .."

