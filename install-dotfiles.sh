#!/bin/bash

ORIGINAL_DIR=$(pwd)
REPO_URL="https://github.com/nzkritik/dotfiles"
REPO_NAME="dotfiles"

is_stow_installed() {
  pacman -Qi "stow" &> /dev/null
}

if ! is_stow_installed; then
  echo "Install stow first"
  exit 1
fi

cd ~

# Check if the repository already exists
if [ -d "$REPO_NAME" ]; then
  echo "Repository '$REPO_NAME' already exists. Skipping clone"
else
  git clone "$REPO_URL"
fi

# Check if the clone was successful
if [ $? -eq 0 ]; then
  echo "removing old configs"
  rm -rf ~/.config/starship.toml

  cd "$REPO_NAME"
  stow tmux
  stow starship
  
  # Check and modify omarchy-launch-screensaver if it exists
  SCREENSAVER_SCRIPT="$HOME/.local/share/omarchy/bin/omarchy-launch-screensaver"
  if [ -f "$SCREENSAVER_SCRIPT" ]; then
    echo "Found omarchy-launch-screensaver script. Modifying..."
    # Backup the original file
    cp "$SCREENSAVER_SCRIPT" "$SCREENSAVER_SCRIPT.bak"
    
    # Replace the line starting with "-e omarchy-cmd-screensaver" with the new command
    sed -i '/^-e omarchy-cmd-screensaver/c\    -e neo-matrix -async --shadingmode=1 --defaultbg --colormode=16' "$SCREENSAVER_SCRIPT"
    
    echo "Successfully updated omarchy-launch-screensaver script"
  else
    echo "omarchy-launch-screensaver script not found at $SCREENSAVER_SCRIPT"
  fi
  
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
    cp -f "$REPO_NAME/icon.png" "$OMARCHY_DIR/"
    cp -f "$REPO_NAME/icon.txt" "$OMARCHY_DIR/"
    cp -f "$REPO_NAME/logo.svg" "$OMARCHY_DIR/"
    cp -f "$REPO_NAME/logo.txt" "$OMARCHY_DIR/"
  else
    echo "Omarchy directory not found at $OMARCHY_DIR"
  fi
else
  echo "Failed to clone the repository."
  exit 1
fi