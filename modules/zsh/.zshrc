for config in "$HOME/.config/zsh/"*.zsh; do
  source "${config}"
done

[ -f "$HOME/local.zsh" ] && source "$HOME/local.zsh"
