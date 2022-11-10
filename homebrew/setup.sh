echo "\n*️⃣  setting up homebrew"

# install homebrew
if [[ ! -x "/opt/homebrew/bin/brew" && ! -x "/usr/local/bin/brew" ]]; then
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  
  if [[ $(uname -m) == 'arm64' ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo "🔧 installed homebrew (apple silicon) ✅"
  else
    echo "🔧 installed homebrew (intel) ✅"
  fi

else
  echo "🔧 homebrew already installed ⏭️"
fi

# load brewfiles
brew bundle --quiet --file homebrew/Brewfile.base --no-lock
echo "⏳ loaded brewfiles ✅"

