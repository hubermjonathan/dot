#!/bin/bash
set -e
DEST=$HOME/Code/dot

if ! xcode-select -p &>/dev/null; then
  echo "installing the Xcode command line tools..."
  xcode-select --install 2>/dev/null || true
  until xcode-select -p &>/dev/null && command -v git &>/dev/null; do sleep 5; done
fi

if [ -d "$DEST/.git" ]; then
  git -C "$DEST" pull --ff-only
else
  mkdir -p "$(dirname "$DEST")"
  git clone https://github.com/hubermjonathan/dot "$DEST"
fi

sudo -v
[ -x /opt/homebrew/bin/brew ] || NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"

rc=0
"$DEST/bin/dot" install || rc=1
"$DEST/bin/dot" link || rc=1
exit $rc
