echo "\n*️⃣  setting up zsh"

# create config folder
if [[ ! -d "$HOME/.config" ]]; then
  mkdir "$HOME/.config"
fi

# remove old configs
rm -r "$HOME/.config/zsh"
echo "🗑️  removed zsh config folder ✅"

# copy zsh configs
cp zsh/.zshrc "$HOME/.zshrc"
echo "📝 copied .zshrc ✅"
mkdir "$HOME/.config/zsh"
cp zsh/shared.zsh "$HOME/.config/zsh/shared.zsh"
echo "📝 copied shared.zsh ✅"

if [[ $(uname -m) == "arm64" ]]; then
  cp zsh/homebrew.zsh "$HOME/.config/zsh/homebrew.zsh"
  echo "📝 copied homebrew.zsh (apple silicon) ✅"
fi

