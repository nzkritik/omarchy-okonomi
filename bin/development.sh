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

# Function to display Development Language selection menu
show_language_menu() {
    # Define Development Language array with: name, description, install script, selected (true/false)
    declare -a languages=(
        "Ruby on Rails|Web application framework written in Ruby|ruby|false" #tested
        "Node.js|JavaScript runtime environment|node|false" #tested
        "Python|High-level programming language|python|false"
        "Go|Statically typed, compiled programming language|go|false"
        "Laravel|PHP web application framework|laravel|false"
        "Symfony|PHP web application framework|symfony|false" 
        "Java|Popular programming language|java|false"
        "Bun|All-in-one JavaScript runtime|bun|false" #tested
        "Rust|Systems programming language focused on safety and performance|rust|false"
        "PHP|Popular general-purpose scripting language|php|false"
        "Elixir|Dynamic, functional language for building scalable applications|elixir|false"
        "Phoenix|Web development framework written in Elixir|phoenix|false"
        "OCaml|General-purpose programming language with an emphasis on expressiveness and safety|ocaml|false" #failed -- error upstream
        "Clojure|Modern, dynamic, and functional dialect of Lisp on the JVM|clojure|false"  
        "Dotnet|Cross-platform framework for building applications|dotnet|false"
    )

    # Build display options and keep track of mapping
    declare -A language_map=()
    declare -a display_options=()
    
    for item in "${languages[@]}"; do
        IFS='|' read -r name desc script selected <<< "$item"
        display_key="$name - $desc"
        display_options+=("$display_key")
        language_map["$display_key"]="$name|$desc|$script"
    done

    # Show Development selection menu
    gum style --foreground 212 --bold "Development Language Installation"
    echo ""
    gum style "Select Development Languages to install (space to toggle, Enter to confirm):"
    echo ""

    selected=$(gum choose --no-limit --height=15 \
        "${display_options[@]}")

    # User cancelled or no selection
    if [[ -z "${selected:-}" ]]; then
        gum style --foreground 244 "No Development Languages selected."
        return 0
    fi

    # Parse selected items and run corresponding scripts
    echo ""
    gum style --foreground 212 --bold "Installing selected Development Languages..."
    echo ""
    
    # Track installation results
    declare -a failed_installs=()
    declare -a successful_installs=()
    
    mapfile -t selected_array <<<"$selected"
    
    for selected_item in "${selected_array[@]}"; do
        # Get the Development language info from the map
        if [[ -n "${language_map[$selected_item]:-}" ]]; then
            IFS='|' read -r name desc script <<< "${language_map[$selected_item]}"
            
            # Create temp file for output
            local output_file
            output_file=$(mktemp)
            
            # Display installation header
            gum style --foreground 212 --bold "→ Installing $name..."
            gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            
            # Run the omarchy-install-dev-env command with the language parameter
            omarchy-install-dev-env "$script" > "$output_file" 2>&1 &
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
    gum style --foreground 40 --bold "Development Language installation complete!"
}

# Function to display Development selection menu
show_development_menu() {
    # Define Development array with: name, description, install script, selected (true/false)
    declare -a developments=(
        "Visual Studio Code|Popular code editor by Microsoft|./bin/install-vscode.sh|false"
        "Sublime Text|Lightweight and fast code editor|./bin/install-sublime-text.sh|false" #tested
        "Postman|API development and testing tool|./bin/install-postman.sh|false" #tested
        "PyCharm|Python IDE by JetBrains - Community Edition|./bin/install-pycharm.sh|false"
        "IntelliJ IDEA|Java IDE by JetBrains|./bin/install-intellij-idea.sh|false"
        "Android Studio|Official IDE for Android development|./bin/install-android-studio.sh|false"
        "waydroid|Run Android apps on Linux|./bin/install-waydroid.sh|false"
        "Anaconda|Python package and envoronment management|./bin/install-anaconda.sh|false"
    )

    # Build display options and keep track of mapping
    declare -A development_map=()
    declare -a display_options=()
    
    for item in "${developments[@]}"; do
        IFS='|' read -r name desc script selected <<< "$item"
        display_key="$name - $desc"
        display_options+=("$display_key")
        development_map["$display_key"]="$name|$desc|$script"
    done

    # Show Development selection menu
    gum style --foreground 212 --bold "Development Tools Installation"
    echo ""
    gum style "Select Development Tools to install (space to toggle, Enter to confirm):"
    echo ""

    selected=$(gum choose --no-limit --height=5 \
        "${display_options[@]}")

    # User cancelled or no selection
    if [[ -z "${selected:-}" ]]; then
        gum style --foreground 244 "No Development Tools selected."
        return 0
    fi

    # Parse selected items and run corresponding scripts
    echo ""
    gum style --foreground 212 --bold "Installing selected Development Tools..."
    echo ""
    
    # Track installation results
    declare -a failed_installs=()
    declare -a successful_installs=()
    
    mapfile -t selected_array <<<"$selected"
    
    for selected_item in "${selected_array[@]}"; do
        # Get the Development info from the map
        if [[ -n "${development_map[$selected_item]:-}" ]]; then
            IFS='|' read -r name desc script <<< "${development_map[$selected_item]}"
            
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
    gum style --foreground 40 --bold "Development Tools installation complete!"
}

# Run the menus
show_language_menu
show_development_menu