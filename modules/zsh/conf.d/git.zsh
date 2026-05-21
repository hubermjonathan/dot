function gp() {
  git pull origin "$(git symbolic-ref --short -q HEAD)"
}

function gm() {
  branch=$(git symbolic-ref --short -q HEAD)
  if git show-ref --verify --quiet refs/heads/main; then
    default=main
  else
    default=master
  fi
  git checkout "$default"
  git pull
  git branch -D "$branch"
}

alias gc="git commit -m"
alias gca="git commit --amend -m"
alias gs="git status"
alias gd="git diff ."
alias gsw="git switch"
alias gco="git checkout"
alias gb="git branch"
alias gbd="git branch -D"
alias gl="git log --oneline --reverse -15"
alias ga="git add ."
alias gf="git fetch"
alias gpo="git push origin"
alias gwt="git worktree list"
alias gwtd="git worktree remove"
