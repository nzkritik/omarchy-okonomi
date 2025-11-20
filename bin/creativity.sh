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

# Function to display creativity selection menu
show_creativity_menu() {
    # Define creativity array with: name, description, install script, selected (true/false)
    declare -a creativity=(
        "DisplayCAL|Open Source Display Calibration and Characterization|./scripts/install-displaycal.sh|false"
        "Rapid Photo|Rapid Photo Downloader for photographers|./scripts/install-rapid-photo.sh|false"
        "Digikam|An advanced digital photo management application|./scripts/install-digikam.sh|false"
        "Darktable|Utility to organize and develop raw images|./scripts/install-darktable.sh|false"
        "Filmulator|Filmulator is a raw photo editing application|./scripts/install-filmulator.sh|false"
        "GIMP|GNU Image Manipulation Program|./scripts/install-gimp.sh|false"
        "Inkscape|Vector graphics editor|./scripts/install-inkscape.sh|false"
        "Krita|Professional free and open source painting program|./scripts/install-krita.sh|false"
        "Blender|3D creation suite|./scripts/install-blender.sh|false"
        "Audacity|Free, open source, cross-platform audio software|./scripts/install-audacity.sh|false"
        "DaVinci Resolve|Professional video editing software|./scripts/install-davinci-resolve.sh|false"
        "WinFF|GUI for ffmpeg for video format conversion|./scripts/install-winff.sh|false"  
        "Scribus|Desktop publishing application|./scripts/install-scribus.sh|false"  
        "Upscayl|Free and Open Source AI Image Upscaler|./scripts/install-upscayl.sh|false"
    )

    # Build display options and keep track of mapping
    declare -A creativity_map=()
    declare -a display_options=()
    
    for item in "${creativity[@]}"; do
        IFS='|' read -r name desc script selected <<< "$item"
        display_key="$name - $desc"
        display_options+=("$display_key")
        creativity_map["$display_key"]="$name|$desc|$script"
    done

    # Show creativity App selection menu
    gum style --foreground 212 --bold "Creativity Installation"
    echo ""
    gum style "Select creativity Apps to install (space to toggle, Enter to confirm):"
    echo ""

    selected=$(gum choose --no-limit --height=15 \
        "${display_options[@]}")

    # User cancelled or no selection
    if [[ -z "${selected:-}" ]]; then
        gum style --foreground 244 "No creativity Apps selected."
        exit 0
    fi

    # Parse selected items and run corresponding scripts
    echo ""
    gum style --foreground 212 --bold "Installing selected creativity Apps..."
    echo ""
    
    mapfile -t selected_array <<<"$selected"
    
    for selected_item in "${selected_array[@]}"; do
        # Get the app info from the map
        if [[ -n "${creativity_map[$selected_item]:-}" ]]; then
            IFS='|' read -r name desc script <<< "${creativity_map[$selected_item]}"
            
            gum spin --title "Installing $name..." -- sleep 0.5
            if [[ -x "$script" ]]; then
                "$script"
                gum style --foreground 40 "✓ $name installed successfully"
            else
                gum warn "$script not found or not executable"
            fi
        fi
    done
    
    echo ""
    gum style --foreground 40 --bold "Creativity App installation complete!"
}

# Run the creativity menu
show_creativity_menu