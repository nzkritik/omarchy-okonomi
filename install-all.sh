#!/bin/bash

set -euo pipefail

# Function to display menu using gum
show_gum_menu() {
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

    # Build selected flags (default all selected except firefox)
    selected_flags=()
    for s in "${install_scripts[@]}"; do
        if [[ "$s" != "install-firefox.sh" ]]; then
            selected_flags+=(--selected "$s")
        fi
    done

    # Run gum choose (allow multiple selections)
    selected=$(gum choose --no-limit --height=14 --header="Select software to install (Use Tab to select/deselect):" \
        "${selected_flags[@]}" "${install_scripts[@]}")

    # user cancelled or no selection
    if [[ -z "${selected:-}" ]]; then
        echo "Installation cancelled or no selection made."
        exit 0
    fi

    # selected is newline-separated; iterate and run scripts
    IFS=$'\n' read -r -d '' -a selected_array <<< "${selected}" || true
    echo
    echo "Installing selected software..."
    for item in "${selected_array[@]}"; do
        echo "-> $item"
        if [[ -x "./$item" ]]; then
            "./$item"
        else
            echo "Warning: $item not executable or not found in current directory."
        fi
    done
    echo "All selected installs attempted."
}

# Function to ask about alternative screensavers using gum
ask_screensavers_with_info() {
    if gum confirm --default --prompt="Do you want to install alternative screensavers?"; then
        # Show multi-line information about options, then prompt selection
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

        # Let user pick one (single choice). Use gum choose with limit 1.
        choice=$(gum choose --limit 1 --height=6 --header="Select a screensaver to install:" \
            "neo-matrix" "sysc-walls")

        if [[ -n "${choice:-}" ]]; then
            case "$choice" in
                neo-matrix)
                    echo "Installing neo-matrix..."
                    if [[ -x "./install-neo-matrix.sh" ]]; then
                        ./install-neo-matrix.sh
                    else
                        echo "install-neo-matrix.sh not found or not executable."
                    fi
                    ;;
                sysc-walls)
                    echo "Installing sysc-walls..."
                    if [[ -x "./install-sysc-walls.sh" ]]; then
                        ./install-sysc-walls.sh
                    else
                        echo "install-sysc-walls.sh not found or not executable."
                    fi
                    ;;
            esac
        else
            echo "No screensaver selected."
        fi
    else
        echo "Skipping alternative screensavers."
    fi
}

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "gum not found. Install gum first: https://github.com/charmbracelet/gum"
    exit 1
fi

# Run main flow
show_gum_menu
ask_screensavers_with_info

# follow-up tasks
if [[ -x "./install-dotfiles.sh" ]]; then
    ./install-dotfiles.sh
else
    echo "install-dotfiles.sh not found or not executable; skipping."
fi

if [[ -x "./remove-apps.sh" ]]; then
    ./remove-apps.sh
else
    echo "remove-apps.sh not found or not executable; skipping."
fi