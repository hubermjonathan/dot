#!/bin/bash
set -e

DEST="$HOME/Code/dot"

if ! xcode-select -p &>/dev/null; then
  echo "installing xcode command line tools..."
  xcode-select --install 2>/dev/null || true
  until xcode-select -p &>/dev/null && command -v git &>/dev/null; do sleep 5; done
fi

mkdir -p "$(dirname "$DEST")"
if [ ! -d "$DEST/.git" ]; then
  echo "cloning hubermjonathan/dot into $DEST..."
  git clone "https://github.com/hubermjonathan/dot" "$DEST"
else
  echo "$DEST already exists, pulling latest..."
  git -C "$DEST" pull --ff-only
fi

cd "$DEST"
exec ./scripts/bootstrap.sh
