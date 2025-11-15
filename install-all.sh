#!/bin/bash

# Remove unwanted apps and install all supplementary apps
./remove-apps.sh
./install-tmux.sh
./install-stow.sh
./install-dotfiles.sh
./install-hyprland-overrides.sh
./install-bitwarden.sh
./install-firefox.sh
./install-vscode.sh
./install-tixati.sh

