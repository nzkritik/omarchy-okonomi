#!/bin/bash

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
            echo "Found omarchy-launch-screensaver script. Modifying..."
            # Backup the original file
            cp "$SCREENSAVER_SCRIPT" "$SCREENSAVER_SCRIPT.bak"
            
            # Replace the line starting with "-e omarchy-cmd-screensaver" with the new command
            # Using a more robust approach to replace the line
            if grep -q "omarchy-cmd-screensaver" "$SCREENSAVER_SCRIPT"; then
                sed -i '/^-e omarchy-cmd-screensaver/c\    -e neo-matrix -async --shadingmode=1 --defaultbg --colormode=16' "$SCREENSAVER_SCRIPT"
                echo "Successfully updated omarchy-launch-screensaver script"
            else
                echo "Warning: Could not find omarchy-cmd-screensaver pattern in script"
                echo "The script may need manual editing"
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