# path
export PATH="$HOME/.local/bin:$PATH"

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
