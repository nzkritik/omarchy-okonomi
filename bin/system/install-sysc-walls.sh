#!/bin/bash

# Install sysc-walls
yay -S --noconfirm --needed sysc-walls

show-enable-menu() {
    # Ask user with gum to use sysc-walls as their screensaver
    echo ""
    use_sysc_walls=$(gum confirm "Do you want to enable sysc-walls as your text based screensaver?")
    if [[ "$use_sysc_walls" == "true" ]]; then
        echo "Enabling sysc-walls as your screensaver..."
        systemctl --user enable --now sysc-walls.service
        if [[ $? -ne 0 ]]; then
            echo "Failed to enable sysc-walls service. Please check the errors above."
            exit 1
        else
            echo "sysc-walls service enabled successfully." 
            systemctl --user start sysc-walls.service
        fi  
    else
        echo "sysc-walls installation complete, but not enabled as screensaver."
    fi
}

# check if installation was successful
if [[ $? -ne 0 ]]; then
    echo "sysc-walls installation failed. Please check the errors above."
    exit 1
else
    echo "sysc-walls installed successfully."
    show-enable-menu
    echo ""
fi  
