export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/Code/dot/bin:$PATH"

tab() {
  echo -ne "\033]0;$*\007"
}

function chpwd() {
  [[ -n $CODING_AGENT ]] && return
  emulate -L zsh
  ls -a
}

function cl() {
  clear
  ls -a
}

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

alias ..="cd .."
alias pbc="pbcopy"
alias pbp="pbpaste"
