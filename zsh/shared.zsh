# prompt
function git_branch() {
  branch=$(git symbolic-ref HEAD 2> /dev/null | awk 'BEGIN{FS="/"} {print $NF}')
  if [[ $branch == "" ]]; then
    echo " "
  else
    echo " ($branch) "
  fi
}
setopt prompt_subst
PROMPT='%~$(git_branch)%F{40}-->%f '

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
function gm() {
  branch=$(git symbolic-ref --short -q HEAD)
  git checkout master
  git branch -D $branch
}
alias gs="git status"
alias gd="git diff ."
alias gsw="git switch"
alias gco="git checkout"
alias gb="git branch"
alias gbd="git branch -D"
alias gl="git log --oneline --reverse"
alias ga="git add ."
alias gp="git pull"
alias gf="git fetch"
alias gpo="git push origin"

# aliases
alias ..="cd .."

