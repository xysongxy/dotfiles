#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"

# Reusable linking function
link_config() {
  local src="$1"
  local dest="$2"

  echo "==> Linking $dest"
  
  # 1. Create parent directory (e.g., ~/.config)
  mkdir -p "$(dirname "$dest")"

  # 2. Backup if it's a real directory or file (and not a symlink)
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    local backup="$dest.backup.$(date +%Y%m%d-%H%M%S)"
    echo "    Backing up existing config to: $backup"
    mv "$dest" "$backup"
  fi

  # 3. Always remove the destination (handles old symlinks)
  rm -rf "$dest"

  # 4. Create the symlink
  ln -s "$src" "$dest"
  echo "    Done."
}

# --- Execute Linking ---

# Link Neovim
link_config "$DOTFILES/nvim" "$HOME/.config/nvim"

# Link Ghostty

link_config "$DOTFILES/ghostty" "$HOME/.config/ghostty"
# Link Zsh (uncomment when ready)
# link_config "$DOTFILES/zsh/.zshrc" "$HOME/.zshrc"

# Link Git (uncomment when ready)
# link_config "$DOTFILES/git/.gitconfig" "$HOME/.gitconfig"


echo "✅ Linking complete!"