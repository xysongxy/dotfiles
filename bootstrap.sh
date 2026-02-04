#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"

# 1) Xcode CLI tools (needed for many builds)
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "Re-run this script after installation finishes."
  exit 0
fi

# 2) Homebrew
if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure brew is on PATH (Handles both Intel and Apple Silicon)
if [[ -f /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -f /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# 3) Install brew deps
# Adding --no-lock avoids cluttering your repo with Brewfile.lock.json
echo "Installing Brewfile packages..."
brew bundle --file "$DOTFILES/Brewfile" --no-lock

# 4) Symlink configs
# Make sure your install.sh is executable
chmod +x "$DOTFILES/install.sh"
"$DOTFILES/install.sh"