for config in "$HOME/.config/zsh/"*.zsh; do
  source "${config}"
done

[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
