#!/bin/bash

set -u

ORIGINAL_DIR=$(pwd)
APP_EXEC="$HOME/.local/share/omarchy/bin/launch-comfyui.sh"
ICON_PATH="$HOME/.local/share/applications/icons/comfyui.png"
DESKTOP_FILE="$HOME/.local/share/applications/ComfyUI.desktop"

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "gum not found. Installing gum..."
    sudo pacman -S --noconfirm --needed gum || {
        echo "Failed to install gum. Please install it manually."
        exit 1
    }
fi

# Function to run installation step with output
run_install_step() {
    local step_name="$1"
    local command="$2"
    
    gum style --foreground 212 --bold "→ $step_name"
    gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    local output_file
    output_file=$(mktemp)
    
    # Run command in background
    eval "$command" > "$output_file" 2>&1 &
    local pid=$!
    
    # Tail output in real-time
    tail -f "$output_file" &
    local tail_pid=$!
    
    # Wait for completion
    if wait $pid 2>/dev/null; then
        kill $tail_pid 2>/dev/null || true
        wait $tail_pid 2>/dev/null || true
        echo ""
        gum style --foreground 40 "✓ $step_name completed successfully"
        rm -f "$output_file"
        return 0
    else
        local exit_code=$?
        kill $tail_pid 2>/dev/null || true
        wait $tail_pid 2>/dev/null || true
        echo ""
        gum style --foreground 1 --bold "✗ $step_name failed (exit code: $exit_code)"
        gum style --foreground 242 "Last output:"
        tail -20 "$output_file" | gum style --foreground 242
        rm -f "$output_file"
        return 1
    fi
}

# Function to detect GPU hardware
detect_gpu_hardware() {
    local nvidia_gpus=()
    local amd_gpus=()
    local apple_gpus=()
    
    # Check for NVIDIA GPUs via lspci
    if command -v lspci &>/dev/null; then
        while IFS= read -r line; do
            nvidia_gpus+=("$line")
        done < <(lspci | grep -i "nvidia\|geforce\|tesla" | cut -d: -f3-)
        
        while IFS= read -r line; do
            amd_gpus+=("$line")
        done < <(lspci | grep -i "amd\|radeon" | cut -d: -f3-)
    fi
    
    # Check for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        apple_gpus=("Apple Silicon")
    fi
    
    # Display detected GPUs
    gum style --foreground 212 --bold "→ Detecting GPU Hardware"
    gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ ${#nvidia_gpus[@]} -gt 0 ]]; then
        gum style --foreground 40 "✓ NVIDIA GPU(s) detected:"
        for gpu in "${nvidia_gpus[@]}"; do
            gum style --foreground 242 "  • ${gpu:0:60}"
        done
        echo ""
    fi
    
    if [[ ${#amd_gpus[@]} -gt 0 ]]; then
        gum style --foreground 40 "✓ AMD GPU(s) detected:"
        for gpu in "${amd_gpus[@]}"; do
            gum style --foreground 242 "  • ${gpu:0:60}"
        done
        echo ""
    fi
    
    if [[ ${#apple_gpus[@]} -gt 0 ]]; then
        gum style --foreground 40 "✓ Apple Silicon detected:"
        for gpu in "${apple_gpus[@]}"; do
            gum style --foreground 242 "  • $gpu"
        done
        echo ""
    fi
    
    # Return GPU type for selection
    if [[ ${#nvidia_gpus[@]} -gt 0 ]]; then
        echo "NVIDIA"
    elif [[ ${#amd_gpus[@]} -gt 0 ]]; then
        echo "AMD"
    elif [[ ${#apple_gpus[@]} -gt 0 ]]; then
        echo "APPLE"
    else
        echo "NONE"
    fi
}

# Function to select GPU
select_gpu() {
    local gpu_type="$1"
    
    if [[ "$gpu_type" == "NONE" ]]; then
        gum style --foreground 1 --bold "✗ No compatible GPU found!"
        gum style --foreground 242 "ComfyUI requires NVIDIA, AMD, or Apple Silicon GPU."
        exit 1
    fi
    
    gum style --foreground 212 --bold "→ GPU Selection"
    gum style "Please select the primary GPU for ComfyUI:"
    echo ""
    
    # Create GPU options based on detected types
    local gpu_options=()
    
    if lspci 2>/dev/null | grep -qi "nvidia\|geforce\|tesla"; then
        gpu_options+=("NVIDIA")
    fi
    
    if lspci 2>/dev/null | grep -qi "amd\|radeon"; then
        gpu_options+=("AMD")
    fi
    
    if [[ $(uname -m) == "arm64" ]]; then
        gpu_options+=("Apple Silicon")
    fi
    
    local selected=$(gum choose "${gpu_options[@]}")
    echo "$selected"
}

# ===== MAIN INSTALLATION FLOW =====

clear
gum style --foreground 212 --bold "ComfyUI Installation"
echo ""
gum style --foreground 242 "This script will install ComfyUI with comfy-cli using Python 3.12 venv."
echo ""

# Step 1: Check and install Python 3.12
gum style --foreground 212 --bold "Step 1/9: Python 3.12 Setup"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! command -v python3.12 &>/dev/null; then
    gum style "Python 3.12 not found. Installing..."
    if ! run_install_step "Installing Python 3.12" "yay -S --noconfirm --needed python312"; then
        exit 1
    fi
else
    gum style --foreground 40 "✓ Python 3.12 is already installed"
fi
echo ""

# Step 2: Create virtual environment
gum style --foreground 212 --bold "Step 2/9: Create Virtual Environment"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ -d "$HOME/comfyenv" ]]; then
    gum style --foreground 244 "⚠ Virtual environment already exists at: $HOME/comfyenv"
    gum style --foreground 244 "Using existing environment..."
else
    if ! run_install_step "Creating Python 3.12 venv" "python3.12 -m venv $HOME/comfyenv"; then
        exit 1
    fi
fi
echo ""

# Step 3: Activate virtual environment and upgrade pip
gum style --foreground 212 --bold "Step 3/9: Activate Environment & Upgrade pip"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

source "$HOME/comfyenv/bin/activate"
if ! run_install_step "Upgrading pip" "$HOME/comfyenv/bin/python -m pip install --upgrade pip"; then
    exit 1
fi
echo ""

# Step 4: Install comfy-cli
gum style --foreground 212 --bold "Step 4/9: Install comfy-cli"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! run_install_step "Installing comfy-cli" "$HOME/comfyenv/bin/python -m pip install comfy-cli"; then
    exit 1
fi
echo ""

# Step 5: Create temporary directory
gum style --foreground 212 --bold "Step 5/9: Setup Temporary Directory"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ! -d "$HOME/comfyenv/tmp" ]]; then
    mkdir -p "$HOME/comfyenv/tmp"
    gum style --foreground 40 "✓ Temporary directory created"
else
    gum style --foreground 244 "⚠ Temporary directory already exists"
fi
export TMPDIR="$HOME/comfyenv/tmp"
gum style --foreground 40 "✓ TMPDIR set to: $TMPDIR"
echo ""

# Step 6: Detect GPU hardware
gum style --foreground 212 --bold "Step 6/9: GPU Hardware Detection"
detected_gpu=$(detect_gpu_hardware)
echo ""

# Step 7: Select GPU
gum style --foreground 212 --bold "Step 7/9: Select Primary GPU"
selected_gpu=$(select_gpu "$detected_gpu")
echo ""
gum style --foreground 40 "✓ Selected GPU: $selected_gpu"
echo ""

# Step 8: Install ComfyUI with appropriate GPU support
gum style --foreground 212 --bold "Step 8/9: Install ComfyUI with GPU Support"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

case "$selected_gpu" in
    "NVIDIA")
        if ! run_install_step "Installing ComfyUI for NVIDIA" "$HOME/comfyenv/bin/comfy install --nvidia"; then
            exit 1
        fi
        ;;
    "AMD")
        if ! run_install_step "Installing ComfyUI for AMD" "$HOME/comfyenv/bin/comfy install --amd"; then
            exit 1
        fi
        ;;
    "Apple Silicon")
        if ! run_install_step "Installing ComfyUI for Apple Silicon" "$HOME/comfyenv/bin/comfy install --m-series"; then
            exit 1
        fi
        ;;
    *)
        gum style --foreground 1 "✗ Unknown GPU type: $selected_gpu"
        exit 1
        ;;
esac
echo ""

# Step 9: Create desktop integration
gum style --foreground 212 --bold "Step 9/9: Desktop Integration"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Copy launch script
cd "$ORIGINAL_DIR"
if [[ -f "bin/aitools/launch-comfyui.sh" ]]; then
    mkdir -p "$(dirname "$APP_EXEC")"
    cp bin/aitools/launch-comfyui.sh "$APP_EXEC"
    chmod +x "$APP_EXEC"
    gum style --foreground 40 "✓ Launch script installed"
else
    gum style --foreground 242 "⚠ Launch script not found in bin/aitools/"
fi
echo ""

# Copy icon
if [[ -f "assets/comfyui.png" ]]; then
    mkdir -p "$(dirname "$ICON_PATH")"
    cp assets/comfyui.png "$ICON_PATH"
    gum style --foreground 40 "✓ Icon installed"
else
    gum style --foreground 242 "⚠ Icon file not found in assets/"
fi
echo ""

# Create desktop file
mkdir -p "$(dirname "$DESKTOP_FILE")"
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Name=ComfyUI
Comment=node-based application for generative AI
Exec=bash -c "source $HOME/comfyenv/bin/activate && comfy launch"
Terminal=true
Type=Application
Icon=$ICON_PATH
StartupNotify=true
Categories=Development;
EOF

chmod +x "$DESKTOP_FILE"
gum style --foreground 40 "✓ Desktop file created"
echo ""

# Installation Summary
echo ""
gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gum style --foreground 40 --bold "✓ ComfyUI Installation Completed Successfully!"
gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

gum style --foreground 212 --bold "Installation Summary:"
echo ""
gum style --foreground 40 "Python Version: 3.12"
gum style --foreground 40 "Virtual Environment: $HOME/comfyenv"
gum style --foreground 40 "GPU Type: $selected_gpu"
gum style --foreground 40 "Temp Directory: $HOME/comfyenv/tmp"
gum style --foreground 40 "Desktop File: $DESKTOP_FILE"
gum style --foreground 40 "Launch Script: $APP_EXEC"
echo ""

gum style --foreground 212 "You can now start ComfyUI by:"
gum style --foreground 212 "1. Using the desktop application (ComfyUI)"
gum style --foreground 212 "2. Running: source $HOME/comfyenv/bin/activate && comfy launch"
gum style --foreground 212 "3. Or simply: $HOME/comfyenv/bin/comfy launch"
echo ""

gum style --foreground 40 "Installation directory: $HOME/.local/share/ComfyUI"
echo ""

cd "$ORIGINAL_DIR"