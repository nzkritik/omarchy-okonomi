#!/bin/bash

set -u

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
        "DisplayCAL|Open Source Display Calibration and Characterization|./bin/install-displaycal.sh|false"
        "Rapid Photo|Rapid Photo Downloader for photographers|./bin/install-rapid-photo.sh|false"
        "Digikam|An advanced digital photo management application|./bin/install-digikam.sh|false"
        "Darktable|Utility to organize and develop raw images|./bin/install-darktable.sh|false"
        "Filmulator|Filmulator is a raw photo editing application|./bin/install-filmulator.sh|false"
        "GIMP|GNU Image Manipulation Program|./bin/install-gimp.sh|false"
        "Inkscape|Vector graphics editor|./bin/install-inkscape.sh|false"
        "Krita|Professional free and open source painting program|./bin/install-krita.sh|false"
        "Blender|3D creation suite|./bin/install-blender.sh|false"
        "Audacity|Free, open source, cross-platform audio software|./bin/install-audacity.sh|false"
        "DaVinci Resolve|Professional video editing software|./bin/install-davinci-resolve.sh|false"
        "WinFF|GUI for ffmpeg for video format conversion|./bin/install-winff.sh|false"  
        "Scribus|Desktop publishing application|./bin/install-scribus.sh|false"  
        "Upscayl|Free and Open Source AI Image Upscaler|./bin/install-upscayl.sh|false"
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
    gum style --foreground 212 --bold "Installing selected creativity Apps. This can take some time..."
    echo ""
    
    # Track installation results
    declare -a failed_installs=()
    declare -a successful_installs=()
    
    mapfile -t selected_array <<<"$selected"
    
    for selected_item in "${selected_array[@]}"; do
        # Get the app info from the map
        if [[ -n "${creativity_map[$selected_item]:-}" ]]; then
            IFS='|' read -r name desc script <<< "${creativity_map[$selected_item]}"
            
            if [[ ! -x "$script" ]]; then
                gum style --foreground 1 "✗ $script not found or not executable"
                failed_installs+=("$name")
                continue
            fi
            
            # Run the installation script and capture errors
            if output=$(gum spin --title "Installing $name..." -- "$script" 2>&1); then
                gum style --foreground 40 "✓ $name installed successfully"
                successful_installs+=("$name")
            else
                exit_code=$?
                gum style --foreground 1 "✗ Failed to install $name (exit code: $exit_code)"
                echo "$output" | gum style --foreground 242
                failed_installs+=("$name")
                # Continue to next installation instead of exiting
                continue
            fi
        fi
    done
    
    # Summary
    echo ""
    gum style --foreground 212 --bold "Installation Summary"
    gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ ${#successful_installs[@]} -gt 0 ]]; then
        gum style --foreground 40 "✓ Successful (${#successful_installs[@]}):"
        for app in "${successful_installs[@]}"; do
            gum style --foreground 40 "  • $app"
        done
    fi
    
    if [[ ${#failed_installs[@]} -gt 0 ]]; then
        echo ""
        gum style --foreground 1 "✗ Failed (${#failed_installs[@]}):"
        for app in "${failed_installs[@]}"; do
            gum style --foreground 1 "  • $app"
        done
    fi
    
    echo ""
    gum style --foreground 40 --bold "Creativity App installation complete!"
}

# Run the creativity menu
show_creativity_menu