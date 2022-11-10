echo "\n*️⃣  setting up vim"

# remove old configs
rm "$HOME/.vimrc"
echo "🗑️  removed vim.rc ✅"
rm -r "$HOME/.vim/colors"
echo "🗑️  removed vim colorschemes ✅"

# install vundle
if [[ ! -e "$HOME/.vim/bundle/Vundle.vim" ]]; then
  git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
  echo "🔧 installed vundle ✅"
else
  echo "🔧 vundle already installed ⏭️"
fi

# copy vim config and colorscheme
cp vim/.vimrc "$HOME/.vimrc"
echo "📝 copied .vimrc ✅"
mkdir "$HOME/.vim/colors"
cp vim/noir.vim "$HOME/.vim/colors/noir.vim"
echo "📝 copied noir.vim ✅"


