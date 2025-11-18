#!/bin/bash

ICON_DIR="$HOME/.local/share/applications/icons"
DESKTOP_DIR="$HOME/.local/share/applications/"

# List of applications to be removed
apps_to_remove=(
    "1password-beta"
    "1password-cli"
    "xournalpp"
    "signal-desktop"
    "typora"
)

# List of web apps to be removed
web_apps_to_remove=(
    "Basecamp"
    "Figma"
    "HEY"
)

# Function to show dialog checklist for apps
show_app_checklist() {
    local app_options=()
    
    # Build dialog options for regular apps
    for i in "${!apps_to_remove[@]}"; do
        app_options+=("$((i+1))" "${apps_to_remove[$i]}" "on")
    done
    
    # Show dialog checklist for regular apps
    selected_apps=$(dialog --clear \
        --checklist "Select applications to remove:" \
        20 60 10 \
        "${app_options[@]}" \
        2>&1 >/dev/tty)
    
    # Check if user cancelled
    if [[ $? -ne 0 ]]; then
        echo "Removal cancelled."
        exit 0
    fi
    
    # Process selected apps
    if [[ -z "$selected_apps" ]]; then
        echo "No applications selected for removal."
        exit 0
    fi
    
    # Convert selected options to array
    IFS=' ' read -ra selected_nums <<< "$selected_apps"
    
    # Remove selected apps
    for num in "${selected_nums[@]}"; do
        index=$((num-1))
        if [[ $index -ge 0 && $index -lt ${#apps_to_remove[@]} ]]; then
            echo "Removing ${apps_to_remove[$index]}..."
            yay -R --noconfirm "${apps_to_remove[$index]}"
        fi
    done
}

# Function to show dialog checklist for web apps
show_web_app_checklist() {
    local web_app_options=()
    
    # Build dialog options for web apps
    for i in "${!web_apps_to_remove[@]}"; do
        web_app_options+=("$((i+1))" "${web_apps_to_remove[$i]}" "on")
    done
    
    # Show dialog checklist for web apps
    selected_web_apps=$(dialog --clear \
        --checklist "Select web applications to remove:" \
        20 60 10 \
        "${web_app_options[@]}" \
        2>&1 >/dev/tty)
    
    # Check if user cancelled
    if [[ $? -ne 0 ]]; then
        echo "Removal cancelled."
        exit 0
    fi
    
    # Process selected web apps
    if [[ -z "$selected_web_apps" ]]; then
        echo "No web applications selected for removal."
        exit 0
    fi
    
    # Convert selected options to array
    IFS=' ' read -ra selected_nums <<< "$selected_web_apps"
    
    # Remove selected web apps
    for num in "${selected_nums[@]}"; do
        index=$((num-1))
        if [[ $index -ge 0 && $index -lt ${#web_apps_to_remove[@]} ]]; then
            echo "Removing ${web_apps_to_remove[$index]}..."
            rm -f "$DESKTOP_DIR/${web_apps_to_remove[$index]}.desktop"
            rm -f "$ICON_DIR/${web_apps_to_remove[$index]}.png"
        fi
    done
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

# Show app checklist
show_app_checklist

# Show web app checklist
show_web_app_checklist

echo "Removal complete!"