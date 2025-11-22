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

# Function to display ai-tool selection menu
show_ai-tool_menu() {
    # Define ai-tool array with: name, description, install script, selected (true/false)
    declare -a ai-tools=(
        "Upscayl|Free and Open Source AI Image Upscaler - GPU Required|./bin/install-upscayl.sh|false"
        "Ollama|Local LLMs on your machine - CPU/GPU Required|./bin/install-ollama.sh|false"
        "LM Studio|Local LLMs on your machine - CPU/GPU Required|./bin/install-lm-studio.sh|false"
        "Open WebUI|Run LLMs with a web interface - CPU/GPU Required|./bin/install-open-webui.sh|false"
        "Automatic1111|Stable Diffusion Web Interface - GPU Required|./bin/install-automatic1111.sh|false"
        "ComfyUI|Stable Diffusion Web Interface - GPU Required|./bin/install-comfyui.sh|false"
        "Clara Verse|AI Image Generation Tool - GPU Required|./bin/install-clara-verse.sh|false"
    )

    # Build display options and keep track of mapping
    declare -A ai-tool_map=()
    declare -a display_options=()
    
    for item in "${ai-tools[@]}"; do
        IFS='|' read -r name desc script selected <<< "$item"
        display_key="$name - $desc"
        display_options+=("$display_key")
        ai-tool_map["$display_key"]="$name|$desc|$script"
    done

    # Show ai-tool selection menu
    gum style --foreground 212 --bold "AI Tool Installation"
    echo ""
    gum style "Select AI Tools to install (space to toggle, Enter to confirm):"
    echo ""

    selected=$(gum choose --no-limit --height=10 \
        "${display_options[@]}")

    # User cancelled or no selection
    if [[ -z "${selected:-}" ]]; then
        gum style --foreground 244 "No ai-tools selected."
        exit 0
    fi

    # Parse selected items and run corresponding scripts
    echo ""
    gum style --foreground 212 --bold "Installing selected ai-tools..."
    echo ""
    
    # Track installation results
    declare -a failed_installs=()
    declare -a successful_installs=()
    
    mapfile -t selected_array <<<"$selected"
    
    for selected_item in "${selected_array[@]}"; do
        # Get the ai-tool info from the map
        if [[ -n "${ai-tool_map[$selected_item]:-}" ]]; then
            IFS='|' read -r name desc script <<< "${ai-tool_map[$selected_item]}"
            
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
    gum style --foreground 40 --bold "ai-tool installation complete!"
}

# Run the ai-tool menu
show_ai-tool_menu