#!/bin/bash
# One-liner installer. Run with:
#   curl -fsSL https://raw.githubusercontent.com/hubermjonathan/dot/main/scripts/install.sh | bash
set -e

REPO="${DOT_REPO:-hubermjonathan/dot}"
DEST="${DOT_DEST:-$HOME/Code/dot}"

# Prime sudo so later steps don't stall on a prompt
sudo -v

# Install Xcode Command Line Tools and block until git is on PATH
if ! xcode-select -p &>/dev/null; then
  echo "installing xcode command line tools..."
  xcode-select --install 2>/dev/null || true
  until xcode-select -p &>/dev/null && command -v git &>/dev/null; do sleep 5; done
fi

# Clone via HTTPS (public repo, no auth required)
mkdir -p "$(dirname "$DEST")"
if [ ! -d "$DEST/.git" ]; then
  echo "cloning $REPO into $DEST..."
  git clone "https://github.com/$REPO" "$DEST"
else
  echo "$DEST already exists, pulling latest..."
  git -C "$DEST" pull --ff-only
fi

cd "$DEST"
exec ./scripts/bootstrap.sh
