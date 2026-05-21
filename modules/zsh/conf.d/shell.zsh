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

# claude code
function c() {
  claude agents \
        --model opus \
        --effort xhigh \
        --dangerously-skip-permissions
}

# aliases
alias ..="cd .."
