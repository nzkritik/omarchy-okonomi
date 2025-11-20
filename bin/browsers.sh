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
        "Firefox|Open-source web browser by Mozilla|./bin/install-firefox.sh|false"
        "Zen Browser|Privacy-focused Firefox fork|./bin/install-zen-browser.sh|false"
        "Tor Browser|Anonymous web browsing over the Tor network|./bin/install-tor-browser.sh|false"
        "Brave|Privacy-focused Chromium-based browser|./bin/install-brave.sh|false"
        "Opera|Feature-rich Chromium-based browser|./bin/install-opera.sh|false"
    )

    # Build display options and keep track of mapping
    declare -A browser_map=()
    declare -a display_options=()
    
    for item in "${browsers[@]}"; do
        IFS='|' read -r name desc script selected <<< "$item"
        display_key="$name - $desc"
        display_options+=("$display_key")
        browser_map["$display_key"]="$name|$desc|$script"
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
    
    for selected_item in "${selected_array[@]}"; do
        # Get the browser info from the map
        if [[ -n "${browser_map[$selected_item]:-}" ]]; then
            IFS='|' read -r name desc script <<< "${browser_map[$selected_item]}"
            
            gum spin --title "Installing $name..." -- sleep 0.5
            if [[ -x "$script" ]]; then
                "$script"
                gum style --foreground 40 "✓ $name installed successfully"
            else
                gum style --foreground 1 "✗ $script not found or not executable"
            fi
        fi
    done
    
    echo ""
    gum style --foreground 40 --bold "Browser installation complete!"
}

# Run the browser menu
show_browser_menu