link .gitconfig ~/.gitconfig
link .gitignore ~/.gitignore
formula git gh
provision gh-auth 'gh auth status >/dev/null 2>&1 || gh auth login --git-protocol ssh --web' 'gh auth status'
