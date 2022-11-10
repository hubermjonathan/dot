# zsh setup
rm -r "$HOME/.config/zsh"
echo "removed zsh config folder"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  echo "installed oh my zsh"
fi

cp .zshrc "$HOME/.zshrc"
echo "copied .zshrc"
mkdir "$HOME/.config/zsh"
cp shared.zsh "$HOME/.config/zsh/shared.zsh"
echo "copied shared.zsh"

# vim setup
rm "$HOME/.vimrc"
echo "removed vim.rc"
rm -r "$HOME/.vim/colors"
echo "removed vim colorschemes"

if [ ! -e "$HOME/.vim/bundle/Vundle.vim" ]; then
  git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"
  echo "installed vundle"
fi

cp .vimrc "$HOME/.vimrc"
echo "copied .vimrc"
mkdir "$HOME/.vim/colors"
cp noir.vim "$HOME/.vim/colors/noir.vim"
echo "copied noir.vim"

