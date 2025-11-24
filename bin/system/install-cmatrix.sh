#!/bin/bash

set -euo pipefail

# Install cmatrix
sudo pacman -S --noconfirm --needed cmatrix

# Function to enable cmatrix as screensaver
enable_cmatrix() {
    # Ask user via gum if they want cmatrix as default screensaver
    if gum confirm --default=false "Do you want cmatrix as your default screensaver?"; then
        SCREENSAVER_SCRIPT="$HOME/.local/share/omarchy/bin/omarchy-launch-screensaver"
        if [[ -f "$SCREENSAVER_SCRIPT" ]]; then
            # Backup with timestamp
            bak="${SCREENSAVER_SCRIPT}.$(date +%Y%m%d%H%M%S).bak"
            cp -a "$SCREENSAVER_SCRIPT" "$bak"
            gum style --foreground 242 "Backed up original to: $bak"
            
            # Count instances of the pattern to replace
            count=$(grep -c '^\s*-e\s\+.*$' "$SCREENSAVER_SCRIPT" || echo "0")
            
            if [[ $count -gt 0 ]]; then
                # Replace all instances of the pattern
                sed -i 's/^\s*-e\s\+.*$/    -e cmatrix -as/g' "$SCREENSAVER_SCRIPT"
                
                gum style --foreground 40 "✓ Set cmatrix as default screensaver in omarchy-launch-screensaver."
                gum style --foreground 40 "  (Replaced $count instance(s))"
            else
                gum style --foreground 244 "⚠ No instances of '-e' found to replace."
            fi
        else
            gum style --foreground 1 "✗ Screensaver script not found at: $SCREENSAVER_SCRIPT"
        fi
    else
        gum style --foreground 244 "cmatrix installed, but not set as the default screensaver."
    fi
    
    gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Check if installation was successful
if [[ $? -eq 0 ]]; then
    gum style --foreground 40 --bold "✓ cmatrix installed successfully."
    echo ""
    enable_cmatrix
else
    gum style --foreground 1 "✗ cmatrix installation failed. Please check the errors above."
    exit 1
fi