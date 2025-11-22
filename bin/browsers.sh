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

# Function to display browser selection menu
show_browser_menu() {
    # Define browser array with: name, description, install script, selected (true/false)
    declare -a browsers=(
        "Firefox|Open-source web browser by Mozilla|./bin/install-firefox.sh|false" #tested
        "Zen Browser|Privacy-focused Firefox fork|./bin/install-zen-browser.sh|false" #tested
        "Tor Browser|Anonymous web browsing over the Tor network|./bin/install-tor-browser.sh|false" #tested
        "Brave|Privacy-focused Chromium-based browser|./bin/install-brave.sh|false" #tested
        "Opera|Feature-rich Chromium-based browser|./bin/install-opera.sh|false" #tested
        #"Vivaldi|Highly customizable Chromium-based browser|./bin/install-vivaldi.sh|false"
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
    
    # Track installation results
    declare -a failed_installs=()
    declare -a successful_installs=()
    
    mapfile -t selected_array <<<"$selected"
    
    for selected_item in "${selected_array[@]}"; do
        # Get the browser info from the map
        if [[ -n "${browser_map[$selected_item]:-}" ]]; then
            IFS='|' read -r name desc script <<< "${browser_map[$selected_item]}"
            
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
    gum style --foreground 40 --bold "Browser installation complete!"
}

# Run the browser menu
show_browser_menu