#!/bin/bash
set -e

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

# Install everything then link configs
echo "running dot install..."
./bin/dot install
echo "running dot link..."
./bin/dot link

echo "done"
