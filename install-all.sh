#!/bin/bash
theme="$PWD/.dialogrc"
export DIALOGRC="$theme"

# Function to display menu using dialog
show_dialog_menu() {
    # Create temporary file for dialog options
    TEMP_FILE=$(mktemp)
    
    # Create array of install scripts (excluding the specified ones)
    install_scripts=(
        "install-tmux.sh"
        "install-stow.sh"
        "install-bitwarden.sh"
        "install-firefox.sh"
        "install-kvm.sh"
        "install-vscode.sh"
        "install-tixati.sh"
        "install-zen-browser.sh"
    )
    
    # Build dialog checklist options
    dialog_options=()
    for i in "${!install_scripts[@]}"; do
        # Default all selections to true except Firefox
        if [[ "${install_scripts[$i]}" == "install-firefox.sh" ]]; then
            dialog_options+=("$((i+1))" "${install_scripts[$i]}" "off")
        else
            dialog_options+=("$((i+1))" "${install_scripts[$i]}" "on")
        fi
    done
    
    # Show dialog checklist
    selected_options=$(dialog --clear \
        --checklist "Select software to install (default all except Firefox):" \
        20 70 10 \
        "${dialog_options[@]}" \
        2>&1 >/dev/tty)
    
    # Check if user cancelled
    if [[ $? -ne 0 ]]; then
        echo "Installation cancelled by user."
        rm -f "$TEMP_FILE"
        exit 0
    fi
    
    # Process selected options
    if [[ -z "$selected_options" ]]; then
        echo "No software selected."
        rm -f "$TEMP_FILE"
        exit 0
    fi
    
    # Execute selected scripts
    echo ""
    echo "Installing selected software..."
    echo "================================"
    
    # Convert selected options to array
    IFS=' ' read -ra selected_nums <<< "$selected_options"
    
    for num in "${selected_nums[@]}"; do
        # Convert 1-based to 0-based index
        index=$((num-1))
        if [[ $index -ge 0 && $index -lt ${#install_scripts[@]} ]]; then
            echo "Installing ${install_scripts[$index]}..."
            "./${install_scripts[$index]}"
            if [[ $? -ne 0 ]]; then
                echo "Error installing ${install_scripts[$index]}"
            fi
        fi
    done
    
    echo ""
    echo "Installation complete!"
    rm -f "$TEMP_FILE"
}

# Function to ask about alternative screensavers
ask_screensavers() {
    # Ask if user wants to install alternative screensavers
    info="Select a screensaver to install:

    neo-matrix
    This screensaver displays falling characters similar to 
    the Matrix movie effect.

    sysc-walls
    This screensaver runs as a systemd service and supports 
    multi-monitor setups.

    Note: 
    sysc-walls will also install Go and the Kitty terminal."
    choice=$(dialog --clear \
        --yesno "Do you want to install alternative screensavers?" \
        10 60 \
        2>&1 >/dev/tty)
    
    if [[ $? -eq 0 ]]; then
        # Show dialog with screensaver options
        screensaver_choice=$(dialog --clear \
            --radiolist "$info" \
            20 70 4 \
            1 "neo-matrix" "on" \
            2 "sysc-walls" "off" \
            2>&1 >/dev/tty)
        
        if [[ $? -eq 0 && -n "$screensaver_choice" ]]; then
            # Process selected screensavers
            IFS=' ' read -ra selected_screensavers <<< "$screensaver_choice"
            
            for screensaver in "${selected_screensavers[@]}"; do
                case "$screensaver" in
                    "neo-matrix")
                        echo "Installing neo-matrix screensaver..."
                        ./install-neo-matrix.sh
                        ;;
                    "sysc-walls")
                        echo "Installing sysc-walls screensaver..."
                        ./install-sysc-walls.sh
                        ;;
                esac
            done
        fi
    fi
}

# Check if dialog is available
if ! command -v dialog &> /dev/null; then
    echo "Dialog tool not found. Installing dialog..."
    sudo pacman -S --noconfirm dialog --needed
    if [[ $? -ne 0 ]]; then
        echo "Failed to install dialog. Exiting."
        exit 1
    fi
fi

# Run the dialog menu
show_dialog_menu
ask_screensavers
./install-dotfiles.sh
./remove-apps.sh