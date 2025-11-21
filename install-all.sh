#!/bin/bash

set -euo pipefail

title="
     _             _       _     _                  
    / \   _ __ ___| |__   | |   (_)_ __  _   ___  __
   / _ \ | '__/ __| '_ \  | |   | | '_ \| | | \ \/ /
  / ___ \| | | (__| | | | | |___| | | | | |_| |>  < 
 /_/   \_\_|  \___|_| |_| |_____|_|_| |_|\__,_/_/\_\
                                                   
"

show_title() {
    gum style --foreground 40 --bold "$title"
    gum style --foreground 212 --bold "   Omarchy Okonomi - Custom Software Installer"
    echo ""
}

# Function to show introductory message
show_gum_menu_intro() {
    gum style --border normal --border-foreground 6 --padding "1 2" \
    "Welcome to the Omarchy Okonomi (Omarchy Customizer)" \
    "" \
    "• Select high-level categories" \
    "• Then choose multiple apps from each."
}
# Function to display menu using gum
show_gum_menu() {
    # Define software array with: name, description, script, selected (true/false)
    declare -a software=(
        "Remove Omarchy Apps|Uninstall default Omarchy applications|./scripts/remove-apps.sh|false"
        "Remove Omarchy Webapps|Uninstall default Omarchy webapps|./scripts/remove-webapps.sh|false"
        "Install Web Browsers|Various web browsers|./bin/browsers.sh|false"
        "Install Creativity Apps|Photo and video editing software suite|./bin/creativity.sh|false"
        "Install Torrent Clients|Popular torrent applications|./bin/torrents.sh|false"
        #"tmux|Terminal multiplexer|./bin/install-tmux.sh|false"
        #"stow|GNU Stow symlink manager|./bin/install-stow.sh|false"
        "Bitwarden|Password manager|./bin/install-bitwarden.sh|false"
        "KVM|Virtualization|./bin/install-kvm.sh|false"
        "VS Code|Code editor|./bin/install-vscode.sh|false"
    )

    # Build display options and keep track of mapping
    declare -A software_map=()
    declare -a display_options=()
    
    for item in "${software[@]}"; do
        IFS='|' read -r name desc script selected <<< "$item"
        display_key="$name - $desc"
        display_options+=("$display_key")
        software_map["$display_key"]="$name|$desc|$script"
    done

    # Run gum choose (allow multiple selections)
    selected=$(gum choose --no-limit --height=14 \
        --header="Select Categories to Customize (space to toggle, Enter to confirm):" \
        "${display_options[@]}")

    # User cancelled or no selection
    if [[ -z "${selected:-}" ]]; then
        gum style --foreground 244 "Installation cancelled or no selection made."
        exit 0
    fi

    # Parse selected items and run corresponding scripts
    echo ""
    gum style --foreground 212 --bold "Lets customize..."
    echo ""
    
    mapfile -t selected_array <<<"$selected"
    
    for selected_item in "${selected_array[@]}"; do
        # Get the software info from the map
        if [[ -n "${software_map[$selected_item]:-}" ]]; then
            IFS='|' read -r name desc script <<< "${software_map[$selected_item]}"
            
            gum spin --title "Installing $name..." -- sleep 0.5
            if [[ -x "$script" ]]; then
                "$script"
                gum style --foreground 40 "✓ $name installed"
            else
                gum style --foreground 1 "$script not found or not executable"
            fi
        fi
    done
    
    echo ""
    gum style --foreground 40 --bold "All selected installations complete!"
}

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "gum not found. Installing gum..."
    sudo pacman -S --noconfirm --needed gum || {
        echo "Failed to install gum. Please install it manually."
        exit 1
    }
fi
clear
# Run main flow
show_title
show_gum_menu_intro
show_gum_menu
echo ""
gum style --foreground 40 --bold "Installation complete! Please reboot your system."