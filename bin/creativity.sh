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
        "DisplayCAL|Open Source Display Calibration and Characterization|./bin/creativity/install-displaycal.sh|false" #tested
        "Rapid Photo|Rapid Photo Downloader for photographers|./bin/creativity/install-rapid-photo.sh|false" #tested
        "Digikam|An advanced digital photo management application|./bin/creativity/install-digikam.sh|false" #tested
        "Darktable|Utility to organize and develop raw images|./bin/creativity/install-darktable.sh|false" #tested
        "GIMP|GNU Image Manipulation Program|./bin/creativity/install-gimp.sh|false" #tested
        "Inkscape|Vector graphics editor|./bin/creativity/install-inkscape.sh|false" #tested
        "Krita|Professional free and open source painting program|./bin/creativity/install-krita.sh|false" #tested
        "Blender|3D creation suite|./bin/creativity/install-blender.sh|false" #tested
        "Audacity|Free, open source, cross-platform audio software|./bin/creativity/install-audacity.sh|false" #tested
        "DaVinci Resolve|Professional video editing software - GPU Required|./bin/creativity/install-davinci-resolve.sh|false"
        "WinFF|GUI for ffmpeg for video format conversion|./bin/creativity/install-winff.sh|false" #tested
        "Scribus|Desktop publishing application|./bin/creativity/install-scribus.sh|false" #tested
        "Upscayl|Free and Open Source AI Image Upscaler - GPU Required|./bin/aitools/install-upscayl.sh|false"
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
            
            # Create temp file for output
            local output_file
            output_file=$(mktemp)
            
            # Display installation header
            gum style --foreground 212 --bold "→ Installing $name..."
            gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            # Run the installation script in background and tail output in real-time
            "$script" > "$output_file" 2>&1 &
            local pid=$!
            
            # Tail the output file in real-time until the process completes
            tail -f "$output_file" &
            local tail_pid=$!
            
            # Wait for the installation to complete
            if wait $pid 2>/dev/null; then
                # Kill the tail process
                kill $tail_pid 2>/dev/null || true
                wait $tail_pid 2>/dev/null || true
                
                # Show final success message
                echo ""
                gum style --foreground 40 --bold "✓ $name installed successfully"
                successful_installs+=("$name")
            else
                exit_code=$?
                # Kill the tail process
                kill $tail_pid 2>/dev/null || true
                wait $tail_pid 2>/dev/null || true
                
                # Show final error message
                echo ""
                gum style --foreground 1 --bold "✗ Failed to install $name (exit code: $exit_code)"
                
                # Show last 10 lines of output for context
                gum style --foreground 242 "Last output:"
                tail -10 "$output_file" | gum style --foreground 242
                
                failed_installs+=("$name")
            fi
            
            # Clean up temp file
            rm -f "$output_file"
            echo ""
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
echo ""