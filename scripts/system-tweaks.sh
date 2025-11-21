#!/bin/bash

# Function to ask about alternative screensavers using gum
ask_screensavers_with_info() {
    if gum confirm --default=false "Do you want to install alternative screensavers?"; then
        cat <<'INFO'

Available screensaver options:

neo-matrix
  - Matrix-style falling characters effect.
  - Installs neo-matrix (AUR) and related packages.
  - Recommended if you want a terminal-style animated screensaver.

sysc-walls
  - Slideshow-based screensaver using feh.
  - Installs feh and configures a systemd service for multi-monitor slideshows.
  - Recommended if you prefer image-based screensavers.

INFO

        # Let user pick one (single choice)
        choice=$(gum choose --limit 1 --height=6 \
            --header="Select a screensaver to install:" \
            "neo-matrix" "sysc-walls")

        if [[ -n "${choice:-}" ]]; then
            case "$choice" in
                neo-matrix)
                    gum spin --title "Installing neo-matrix..." -- sleep 0.5
                    if [[ -x "./bin/install-neo-matrix.sh" ]]; then
                        ./bin/install-neo-matrix.sh
                    else
                        gum warn "install-neo-matrix.sh not found or not executable."
                    fi
                    ;;
                sysc-walls)
                    gum spin --title "Installing sysc-walls..." -- sleep 0.5
                    if [[ -x "./bin/install-sysc-walls.sh" ]]; then
                        ./bin/install-sysc-walls.sh
                    else
                        gum warn "install-sysc-walls.sh not found or not executable."
                    fi
                    ;;
            esac
        else
            gum style --foreground 244 "No screensaver selected."
        fi
    else
        gum style --foreground 244 "Skipping alternative screensavers."
    fi
}

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "gum not found. Installing gum..."
    sudo pacman -S --noconfirm --needed gum || {
        echo "Failed to install gum. Please install it manually."
        exit 1
    }
fi


ask_screensavers_with_info

#clear


# Follow-up tasks
#echo ""
#gum style --foreground 212 --bold "Running post-install configurations..."
#echo ""
#
#if [[ -x "./scripts/install-dotfiles.sh" ]]; then
#    gum spin --title "Setting up dotfiles..." -- ./scripts/install-dotfiles.sh
#else
#    gum style --foreground 1 "✗ Failed (install-dotfiles.sh not found or not executable; skipping.):"
#fi
#
#if [[ -x "./scripts/remove-apps.sh" ]]; then
#    gum spin --title "Removing unwanted applications..." -- ./scripts/remove-apps.sh
#else
#    gum style --foreground 1 "✗ Failed (remove-apps.sh not found or not executable; skipping.):"
#fi