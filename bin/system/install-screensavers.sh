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

# Function to display screensaver selection menu
show_screensaver_menu() {
    # Define screensaver array with: name, description, install script, selected (true/false)
    declare -a screensavers=(
        "cmatrix|Terminal Matrix screensaver|./bin/system/install-cmatrix.sh|false"
        "Neo Matrix|Futuristic Matrix-style screensaver|./bin/system/install-neo-matrix.sh|false"
        "sysc-wall|Text based screensaver|./bin/system/install-sysc-wall.sh|false" #tested
    )

    # Build display options and keep track of mapping
    declare -A screensaver_map=()
    declare -a display_options=()
    
    for item in "${screensavers[@]}"; do
        IFS='|' read -r name desc script selected <<< "$item"
        display_key="$name - $desc"
        display_options+=("$display_key")
        screensaver_map["$display_key"]="$name|$desc|$script"
    done

    # Show screensaver selection menu
    gum style --foreground 212 --bold "Web screensaver Installation"
    echo ""
    gum style "Select screensavers to install (space to toggle, Enter to confirm):"
    echo ""

    selected=$(gum choose --no-limit --height=10 \
        "${display_options[@]}")

    # User cancelled or no selection
    if [[ -z "${selected:-}" ]]; then
        gum style --foreground 244 "No screensavers selected."
        exit 0
    fi

    # Parse selected items and run corresponding scripts
    echo ""
    gum style --foreground 212 --bold "Installing selected screensavers..."
    echo ""
    
    # Track installation results
    declare -a failed_installs=()
    declare -a successful_installs=()
    
    mapfile -t selected_array <<<"$selected"
    
    for selected_item in "${selected_array[@]}"; do
        # Get the screensaver info from the map
        if [[ -n "${screensaver_map[$selected_item]:-}" ]]; then
            IFS='|' read -r name desc script <<< "${screensaver_map[$selected_item]}"
            
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
    gum style --foreground 40 --bold "Screensaver installation complete!"
}

# Run the screensaver menu
show_screensaver_menu
echo ""