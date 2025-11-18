#!/bin/bash

ORIGINAL_DIR=$(pwd)
REPO_URL="https://github.com/nzkritik/dotfiles"
REPO_NAME="dotfiles"

# Install neo-matrix
yay -S --noconfirm --needed neo-matrix

# Verify installation
if command -v neo-matrix &> /dev/null; then
    echo "neo-matrix installed successfully"
    
    # Ask user if they want neo-matrix as default screensaver
    read -p "Do you want neo-matrix as your default screensaver? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Check and modify omarchy-launch-screensaver if it exists
        SCREENSAVER_SCRIPT="$HOME/.local/share/omarchy/bin/omarchy-launch-screensaver"
        if [ -f "$SCREENSAVER_SCRIPT" ]; then
            echo "Found omarchy-launch-screensaver script. Backing up..."
            # Backup the original file
            cp "$SCREENSAVER_SCRIPT" "$SCREENSAVER_SCRIPT.bak"
            cd ~
            # Check if the repository already exists
            if [ -d "$REPO_NAME" ]; then
            echo "Repository '$REPO_NAME' already exists. Skipping clone"
            else
            git clone "$REPO_URL"
            fi
            NEW_SCRIPT="$REPO_NAME/omarchy/omarchy-launch-screensaver"
            
            # Replace the original omarchy-cmd-screensaver with the new version with neo-matrix
            if [ -f "$NEW_SCRIPT" ]; then
                cp  "$NEW_SCRIPT" "$SCREENSAVER_SCRIPT"
                echo "Successfully updated omarchy-launch-screensaver"
            else
                echo "omarchy-launch-screensaver not updated"
            fi
        else
            echo "omarchy-launch-screensaver script not found at $SCREENSAVER_SCRIPT"
            echo "Please ensure the script exists and is properly configured"
        fi
    else
        echo "Skipping neo-matrix as default screensaver"
    fi
else
    echo "Failed to install neo-matrix"
    exit 1
fi