#!/bin/bash
set -e

# Cache sudo credentials so homebrew install runs without prompting mid-script
sudo -v

# Create ~/Code so cloned repos have a home
mkdir -p ~/Code

# Install Homebrew
if ! command -v brew &>/dev/null; then
  echo "installing homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install Go
if ! command -v go &>/dev/null; then
  echo "installing go..."
  brew install go
fi

# Build dot
cd "$(dirname "$0")"
echo "building dot..."
go build -o bin/dot ./cmd/dot

# Force homebrew onto the PATH
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

# Install everything then link configs
echo "running dot install..."
./bin/dot install
echo "running dot link..."
./bin/dot link

echo "done"
