echo "\n*️⃣  setting up git"

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

