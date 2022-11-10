# load zsh files
for config in "$HOME/.config/zsh/"*.zsh; do
  source "${config}"
done

for config in "$HOME/"*.zsh; do
  source "${config}"
done

unset config

