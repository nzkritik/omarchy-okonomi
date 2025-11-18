#!/bin/bash

# Function to display menu and get user selection
show_menu() {
    echo "Select software to install (default all except Firefox):"
    echo "======================================================"
    
    # Create array of install scripts (excluding the specified ones)
    install_scripts=(
        "install-tmux.sh"
        "install-stow.sh"
        "install-neo-matrix.sh"
        "install-bitwarden.sh"
        "install-firefox.sh"
        "install-kvm.sh"
        "install-sysc-walls.sh"
        "install-vscode.sh"
        "install-tixati.sh"
        "install-zen-browser.sh"
    )
    
    # Initialize selections array
    selections=()
    
    # Default all selections to true except Firefox
    for script in "${install_scripts[@]}"; do
        if [[ "$script" == "install-firefox.sh" ]]; then
            selections+=("false")
        else
            selections+=("true")
        fi
    done
    
    # Display menu
    for i in "${!install_scripts[@]}"; do
        script_name="${install_scripts[$i]}"
        if [[ "${selections[$i]}" == "true" ]]; then
            echo "[$i+1] [X] $script_name"
        else
            echo "[$i+1] [ ] $script_name"
        fi
    done
    
    echo ""
    echo "Enter selection numbers (comma separated, e.g. 1,3,5) or 'all' to select all, 'none' to select none:"
    read -r input
    
    # Process input
    if [[ "$input" == "all" ]]; then
        for i in "${!install_scripts[@]}"; do
            selections[$i]="true"
        done
    elif [[ "$input" == "none" ]]; then
        for i in "${!install_scripts[@]}"; do
            selections[$i]="false"
        done
    elif [[ -n "$input" ]]; then
        # Clear selections
        for i in "${!install_scripts[@]}"; do
            selections[$i]="false"
        done
        
        # Parse comma-separated input
        IFS=',' read -ra nums <<< "$input"
        for num in "${nums[@]}"; do
            if [[ "$num" =~ ^[0-9]+$ ]] && [[ "$num" -ge 1 ]] && [[ "$num" -le "${#install_scripts[@]}" ]]; then
                selections[$((num-1))]="true"
            fi
        done
    fi
    
    # Execute selected scripts
    echo ""
    echo "Installing selected software..."
    echo "================================"
    
    for i in "${!install_scripts[@]}"; do
        if [[ "${selections[$i]}" == "true" ]]; then
            echo "Installing ${install_scripts[$i]}..."
            "./${install_scripts[$i]}"
            if [[ $? -ne 0 ]]; then
                echo "Error installing ${install_scripts[$i]}"
            fi
        fi
    done
    
    echo ""
    echo "Installation complete!"
}

# Run the menu
show_menu