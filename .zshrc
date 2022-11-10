# load zsh files
for conf in "$HOME/.config/zsh/"*.zsh; do
  source "${conf}"
done

for conf in "$HOME/"*.zsh; do
  source "${conf}"
done

unset conf

