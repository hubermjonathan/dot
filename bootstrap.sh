#!/bin/bash
set -e

# Install or upgrade Xcode Command Line Tools
if ! xcode-select -p &>/dev/null; then
  echo "installing xcode command line tools..."
  xcode-select --install 2>/dev/null || true
  until xcode-select -p &>/dev/null; do sleep 5; done
else
  echo "checking for xcode command line tools updates..."
  clt_label=$(softwareupdate --list 2>/dev/null \
    | grep -E '\* (Label: )?Command Line Tools' \
    | tail -1 | sed -E 's/^[* ]*(Label: )?//' | xargs)
  if [ -n "$clt_label" ]; then
    echo "upgrading: $clt_label"
    sudo softwareupdate -i "$clt_label"
  fi
fi

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
