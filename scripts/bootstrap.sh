#!/bin/bash
set -e

sudo -v
[ -x /opt/homebrew/bin/brew ] || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

if ! command -v go &>/dev/null; then
  echo "installing go..."
  brew install go
fi

cd "$(dirname "$0")/.."
echo "building dot..."
go build -o bin/dot ./cmd/dot

echo "running dot install..."
./bin/dot install
echo "running dot link..."
./bin/dot link

echo "done"
