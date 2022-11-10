### zsh setup ###
echo "\n1️⃣  setting up zsh"

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


### vim setup ###
echo "\n2️⃣  setting up vim"

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


### git setup ###
echo "\n3️⃣  setting up git"

# remove old configs
rm "$HOME/.gitconfig"
echo "🗑️  removed .gitconfig ✅"
rm "$HOME/.gitignore"
echo "🗑️  removed .gitignore ✅"

# copy .gitignore
cp git/.gitignore "$HOME/.gitignore"

# configure git
git config --global user.name "Jon Huber"
git config --global user.email "hubermjonathan@gmail.com"
git config --global pager.branch false
git config --global pull.rebase false
git config --global core.excludesfile "$HOME/.gitignore"
echo "📝 wrote .gitconfig ✅"

# create ssh key
if [[ ! -e "$HOME/.ssh/id_ed25519" ]]; then
  ssh-keygen -t ed25519 -C "hubermjonathan@gmail.com" -f "$HOME/.ssh/id_ed25519" -N "" -q
  cat "$HOME/.ssh/id_ed25519.pub" | pbcopy
  echo "💻 created ssh key and copied to clipboard ✅:"
  echo "add it to github here -> https://github.com/settings/ssh/new"
else
  echo "💻 ssh key already exists ⏭️"
fi


### homebrew setup ###
echo "\n4️⃣  setting up homebrew"

# install homebrew
if [[ ! -x "/opt/homebrew/bin/brew" && ! -x "/usr/local/bin/brew" ]]; then
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "🔧 installed homebrew ✅"
else
  echo "🔧 homebrew already installed ⏭️"
fi

