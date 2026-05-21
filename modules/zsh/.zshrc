for config in "$HOME/.config/zsh/"*.zsh; do
  source "${config}"
done

for config in "$HOME/"*.local.zsh; do
  source "${config}"
done
