#!/bin/bash

set -euo pipefail

# Function to display menu using gum
show_gum_menu() {
    # Define software array with: name, description, script, selected (true/false)
    declare -a software=(
        "Web Browsers|Various web browsers|./bin/browsers.sh|false"
        "Creativity Apps|Photo and video editing software suite|./bin/creativity.sh|false"
        "tmux|Terminal multiplexer|./bin/install-tmux.sh|false"
        "stow|GNU Stow symlink manager|./bin/install-stow.sh|false"
        "neo-matrix|Matrix-style screensaver|./bin/install-neo-matrix.sh|false"
        "Bitwarden|Password manager|./bin/install-bitwarden.sh|false"
        "KVM|Virtualization|./bin/install-kvm.sh|false"
        "Sysc Walls|Wallpaper manager|./bin/install-sysc-walls.sh|false"
        "VS Code|Code editor|./bin/install-vscode.sh|false"
        "Tixati|Torrent client|./bin/install-tixati.sh|false"
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
        --header="Select software to install (space to toggle, Enter to confirm):" \
        "${display_options[@]}")

    # User cancelled or no selection
    if [[ -z "${selected:-}" ]]; then
        gum style --foreground 244 "Installation cancelled or no selection made."
        exit 0
    fi

    # Parse selected items and run corresponding scripts
    echo ""
    gum style --foreground 212 --bold "Installing selected software..."
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
                gum warn "$script not found or not executable"
            fi
        fi
    done
    
    echo ""
    gum style --foreground 40 --bold "All selected installations complete!"
}

# Function to ask about alternative screensavers using gum
ask_screensavers_with_info() {
    if gum confirm --default=false "Do you want to install alternative screensavers?"; then
        cat <<'INFO'

Available screensaver options:

neo-matrix
  - Matrix-style falling characters effect.
  - Installs neo-matrix (AUR) and related packages.
  - Recommended if you want a terminal-style animated screensaver.

sysc-walls
  - Slideshow-based screensaver using feh.
  - Installs feh and configures a systemd service for multi-monitor slideshows.
  - Recommended if you prefer image-based screensavers.

INFO

        # Let user pick one (single choice)
        choice=$(gum choose --limit 1 --height=6 \
            --header="Select a screensaver to install:" \
            "neo-matrix" "sysc-walls")

        if [[ -n "${choice:-}" ]]; then
            case "$choice" in
                neo-matrix)
                    gum spin --title "Installing neo-matrix..." -- sleep 0.5
                    if [[ -x "./bin/install-neo-matrix.sh" ]]; then
                        ./bin/install-neo-matrix.sh
                    else
                        gum warn "install-neo-matrix.sh not found or not executable."
                    fi
                    ;;
                sysc-walls)
                    gum spin --title "Installing sysc-walls..." -- sleep 0.5
                    if [[ -x "./bin/install-sysc-walls.sh" ]]; then
                        ./bin/install-sysc-walls.sh
                    else
                        gum warn "install-sysc-walls.sh not found or not executable."
                    fi
                    ;;
            esac
        else
            gum style --foreground 244 "No screensaver selected."
        fi
    else
        gum style --foreground 244 "Skipping alternative screensavers."
    fi
}

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "gum not found. Installing gum..."
    sudo pacman -S --noconfirm --needed gum || {
        echo "Failed to install gum. Please install it manually."
        exit 1
    }
fi

# Run main flow
show_gum_menu
clear
ask_screensavers_with_info

# Follow-up tasks
echo ""
gum style --foreground 212 --bold "Running post-install configurations..."
echo ""

if [[ -x "./bin/install-dotfiles.sh" ]]; then
    gum spin --title "Setting up dotfiles..." -- ./bin/install-dotfiles.sh
else
    gum warn "install-dotfiles.sh not found or not executable; skipping."
fi

if [[ -x "./bin/remove-apps.sh" ]]; then
    gum spin --title "Removing unwanted applications..." -- ./bin/remove-apps.sh
else
    gum warn "remove-apps.sh not found or not executable; skipping."
fi

echo ""
gum style --foreground 40 --bold "Installation complete! Please reboot your system."