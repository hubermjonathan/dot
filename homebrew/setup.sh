echo "\n*️⃣  setting up homebrew"

# install homebrew
if [[ ! -x "/opt/homebrew/bin/brew" && ! -x "/usr/local/bin/brew" ]]; then
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo "🔧 installed homebrew ✅"
else
  echo "🔧 homebrew already installed ⏭️"
fi

