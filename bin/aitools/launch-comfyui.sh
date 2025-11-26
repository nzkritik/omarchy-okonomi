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

# Display header
gum style --foreground 212 --bold "ComfyUI Launcher"
echo ""

# Check if ComfyUI directory exists
if [[ ! -d "$HOME/ComfyUI" ]]; then
    gum style --foreground 1 --bold "✗ ComfyUI directory not found"
    gum style --foreground 242 "Expected location: $HOME/ComfyUI"
    echo ""
    gum style --foreground 244 "Please install ComfyUI first by running the installation script."
    exit 1
fi

gum style --foreground 40 "✓ ComfyUI directory found at: $HOME/ComfyUI"
echo ""

# Check if conda is installed
if ! command -v conda &>/dev/null; then
    gum style --foreground 1 --bold "✗ Conda not found"
    gum style --foreground 242 "Conda is required to run ComfyUI."
    echo ""
    gum style --foreground 244 "Please install Miniconda by running:"
    gum style --foreground 212 "  yay -S --noconfirm --needed miniconda3"
    exit 1
fi

gum style --foreground 40 "✓ Conda is installed"
echo ""

# Check if comfyenv conda environment exists
if ! conda env list | grep -q "comfyenv"; then
    gum style --foreground 1 --bold "✗ ComfyUI conda environment not found"
    gum style --foreground 242 "Expected environment: comfyenv"
    echo ""
    gum style --foreground 244 "Please run the installation script to create the environment."
    exit 1
fi

gum style --foreground 40 "✓ ComfyUI conda environment found"
echo ""

# Check if python main.py exists
if [[ ! -f "$HOME/ComfyUI/main.py" ]]; then
    gum style --foreground 1 --bold "✗ ComfyUI main.py not found"
    gum style --foreground 242 "Expected location: $HOME/ComfyUI/main.py"
    echo ""
    gum style --foreground 244 "ComfyUI installation may be incomplete. Please reinstall."
    exit 1
fi

gum style --foreground 40 "✓ ComfyUI main.py found"
echo ""

# All checks passed - launch ComfyUI
gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gum style --foreground 40 --bold "Launching ComfyUI..."
echo ""

# Source conda initialization and launch
eval "$(conda shell.bash hook)" 2>/dev/null || true
cd "$HOME/ComfyUI"
conda activate comfyenv
python main.py

# If we get here, ComfyUI has exited
exit_code=$?
echo ""
gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ $exit_code -eq 0 ]]; then
    gum style --foreground 40 "✓ ComfyUI closed successfully"
else
    gum style --foreground 1 "✗ ComfyUI exited with error code: $exit_code"
fi

exit $exit_code