#!/bin/bash

ORIGINAL_DIR=$(pwd)
REPO_URL="https://github.com/nzkritik/dotfiles"
REPO_NAME="dotfiles"

cd ~
# Check if the repository already exists
if [ -d "$REPO_NAME" ]; then
  echo "Repository '$REPO_NAME' already exists. Skipping clone"
else
  git clone "$REPO_URL"
fi

copy_icons() {
  # Remove specified files from ~/.local/share/omarchy/
  OMARCHY_DIR="$HOME/.local/share/omarchy"
  if [ -d "$OMARCHY_DIR" ]; then
    echo "Removing specified files from $OMARCHY_DIR"
    rm -f "$OMARCHY_DIR/icon.png"
    rm -f "$OMARCHY_DIR/icon.txt"
    rm -f "$OMARCHY_DIR/logo.svg"
    rm -f "$OMARCHY_DIR/logo.txt"
    
    # Copy replacements from dotfiles folder
    echo "Copying replacement files from dotfiles" 
    cp -f "icon.png" "$OMARCHY_DIR"
    cp -f "icon.txt" "$OMARCHY_DIR"
    cp -f "logo.svg" "$OMARCHY_DIR"
    cp -f "logo.txt" "$OMARCHY_DIR"
  else
    echo "Omarchy directory not found at $OMARCHY_DIR"
  fi
}

# Check if the clone was successful
if [ $? -eq 0 ]; then
  is_stow_installed() {
    pacman -Qi "stow" &> /dev/null
  }

  is_tmux_installed() {
    command -v tmux &> /dev/null
  }

  if ! is_stow_installed; then
    echo "stow not found. Installing..."
    ./install-stow.sh
  fi

  if is_tmux_installed; then
    cd "$REPO_NAME"
    stow tmux
    cd "$ORIGINAL_DIR"
  fi
  echo "removing old configs"
  rm -rf ~/.config/starship.toml

  cd "$REPO_NAME"
  stow starship
  stow fastfetch
else
  echo "Failed to clone the repository."
  exit 1
fi

# copy_icons
