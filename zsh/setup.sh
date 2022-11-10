echo "\n*️⃣  setting up zsh"

# remove old configs
rm -r "$HOME/.config/zsh"
echo "🗑️  removed zsh config folder ✅"

# install oh my zsh
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  echo "🔧 installed oh my zsh ✅"
else
  echo "🔧 oh my zsh already installed ⏭️"
fi

# copy zsh configs
cp zsh/.zshrc "$HOME/.zshrc"
echo "📝 copied .zshrc ✅"
mkdir "$HOME/.config/zsh"
cp zsh/shared.zsh "$HOME/.config/zsh/shared.zsh"
echo "📝 copied shared.zsh ✅"

