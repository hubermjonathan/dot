function gc() {
  git commit -m "$1"
}
function gca() {
  git commit --amend -m "$1"
}
function gt() {
  git tag -a "$1" "$2" -m "$1"
}
function gm() {
  branch=$(git symbolic-ref --short -q HEAD)
  git checkout main
  git branch -D "$branch"
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
