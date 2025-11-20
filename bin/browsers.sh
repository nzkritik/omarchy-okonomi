#!/bin/bash

set -euo pipefail

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "gum not found. Installing gum..."
    sudo pacman -S --noconfirm --needed gum || {
        echo "Failed to install gum. Please install it manually."
        exit 1
    }
fi

# Function to display browser selection menu
show_browser_menu() {
    # Define browser array with: name, description, install script, selected (true/false)
    declare -a browsers=(
        "Firefox|Open-source web browser by Mozilla|./scripts/install-firefox.sh|false"
        "Zen Browser|Privacy-focused Firefox fork|./scripts/install-zen-browser.sh|false"
        "Tor Browser|Anonymous web browsing over the Tor network|./scripts/install-tor-browser.sh|false"
        "Brave|Privacy-focused Chromium-based browser|./scripts/install-brave.sh|false"
        "Opera|Feature-rich Chromium-based browser|./scripts/install-opera.sh|false"
    )

    # Build display options
    declare -a display_options=()
    
    for item in "${browsers[@]}"; do
        IFS='|' read -r name desc script selected <<< "$item"
        display_options+=("$name - $desc")
    done

    # Show browser selection menu
    gum style --foreground 212 --bold "Web Browser Installation"
    echo ""
    gum style "Select browsers to install (space to toggle, Enter to confirm):"
    echo ""

    selected=$(gum choose --no-limit --height=10 \
        "${display_options[@]}")

    # User cancelled or no selection
    if [[ -z "${selected:-}" ]]; then
        gum style --foreground 244 "No browsers selected."
        exit 0
    fi

    # Parse selected items and run corresponding scripts
    echo ""
    gum style --foreground 212 --bold "Installing selected browsers..."
    echo ""
    
    mapfile -t selected_array <<<"$selected"
    
    for selected_name in "${selected_array[@]}"; do
        # Find matching script for selected name
        for item in "${browsers[@]}"; do
            IFS='|' read -r name desc script _ <<< "$item"
            if [[ "$name" == "$selected_name" ]]; then
                gum spin --title "Installing $name..." -- sleep 0.5
                if [[ -x "$script" ]]; then
                    "$script"
                    gum style --foreground 40 "✓ $name installed successfully"
                else
                    gum warn "$script not found or not executable"
                fi
                break
            fi
        done
    done
    
    echo ""
    gum style --foreground 40 --bold "Browser installation complete!"
}

# Run the browser menu
show_browser_menu