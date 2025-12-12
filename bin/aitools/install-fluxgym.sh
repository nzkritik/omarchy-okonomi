#!/bin/bash

set -u

ORIGINAL_DIR=$(pwd)
INSTALL_DIR="$HOME/fluxgym"
DESKTOP_FILE="$HOME/.local/share/applications/FluxGym.desktop"
ICON_PATH="$HOME/.local/share/applications/icons/fluxgym.png"
LAUNCH_SCRIPT_SRC="$ORIGINAL_DIR/scripts/launch-fluxgym.sh"
LAUNCH_SCRIPT_DEST="$HOME/.local/share/fluxgym/launch-fluxgym.sh"
CUDA_VERSION="12.1"

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "gum not found. Installing gum..."
    sudo pacman -S --noconfirm --needed gum || {
        echo "Failed to install gum. Please install it manually."
        exit 1
    }
fi

# Function to confirm or change installation directory
confirm_install_directory() {
    gum style --foreground 212 --bold "Installation Directory Configuration"
    gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    gum style "Default installation directory:"
    gum style --foreground 40 "  $INSTALL_DIR"
    echo ""
    
    if gum confirm --default=true "Do you want to use this directory?"; then
        gum style --foreground 40 "✓ Using default installation directory"
        echo ""
        return 0
    fi
    
    # Prompt for custom directory
    echo ""
    gum style "Enter custom installation directory (or press Enter to use default):"
    custom_dir=$(gum input --placeholder "$INSTALL_DIR")
    
    if [[ -z "$custom_dir" ]]; then
        gum style --foreground 244 "No input provided. Using default directory."
        echo ""
        return 0
    fi
    
    # Expand ~ to home directory
    custom_dir="${custom_dir/#\~/$HOME}"
    
    # Validate path
    if [[ ! "$custom_dir" =~ ^/ ]]; then
        gum style --foreground 1 "✗ Please provide an absolute path (starting with /)"
        echo ""
        confirm_install_directory
        return
    fi
    
    gum style --foreground 212 "New installation directory:"
    gum style --foreground 40 "  $custom_dir"
    echo ""
    
    if gum confirm --default=true "Confirm this directory?"; then
        INSTALL_DIR="$custom_dir"
        DESKTOP_FILE="$HOME/.local/share/applications/FluxGym.desktop"
        ICON_PATH="$HOME/.local/share/applications/icons/fluxgym.png"
        gum style --foreground 40 "✓ Installation directory set to: $INSTALL_DIR"
        echo ""
        return 0
    else
        gum style --foreground 244 "Directory change cancelled. Trying again..."
        echo ""
        confirm_install_directory
    fi
}

# Function to select CUDA version
select_cuda_version() {
    gum style --foreground 212 --bold "CUDA Version Selection"
    gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    gum style "Select CUDA version for PyTorch installation:"
    echo ""
    
    local selected=$(gum choose \
        "11.8 (cu118) - Older NVIDIA GPUs" \
        "12.1 (cu121) - Standard NVIDIA support (recommended)" \
        "12.8 (cu128) - RTX 50-series (5090, etc.)")
    
    case "$selected" in
        *"11.8"*)
            CUDA_VERSION="11.8"
            ;;
        *"12.1"*)
            CUDA_VERSION="12.1"
            ;;
        *"12.8"*)
            CUDA_VERSION="12.8"
            ;;
    esac
    
    echo ""
    gum style --foreground 40 "✓ Selected CUDA version: $CUDA_VERSION"
    echo ""
}

# Function to check and install Python 3.10
check_python_310() {
    gum style --foreground 212 --bold "Step 1/11: Check Python 3.10"
    gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if ! command -v python3.10 &>/dev/null; then
        gum style "Python 3.10 not found. Installing..."
        if ! run_install_step "Installing Python 3.10" "yay -S --noconfirm --needed python310"; then
            exit 1
        fi
    else
        python_version=$(python3.10 --version)
        gum style --foreground 40 "✓ $python_version is already installed"
    fi
    echo ""
}

# Function to run installation step with live output
run_install_step() {
    local step_name="$1"
    local command="$2"
    
    gum style --foreground 212 --bold "→ $step_name"
    gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Run command directly to preserve color formatting
    eval "$command"
    local exit_code=$?
    
    echo ""
    
    if [[ $exit_code -eq 0 ]]; then
        gum style --foreground 40 "✓ $step_name completed successfully"
        return 0
    else
        gum style --foreground 1 --bold "✗ $step_name failed (exit code: $exit_code)"
        return 1
    fi
}

# ===== MAIN INSTALLATION FLOW =====

clear
gum style --foreground 212 --bold "FluxGym Installation"
echo ""
gum style --foreground 242 "This script will install FluxGym with sd-scripts and PyTorch."
echo ""

# Step 0a: Confirm installation directory
confirm_install_directory

# Step 0b: Select CUDA version
select_cuda_version

# Step 1: Check and install Python 3.10
check_python_310

# Step 2: Clone repositories
gum style --foreground 212 --bold "Step 2/11: Clone Repositories"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ -d "$INSTALL_DIR" ]]; then
    gum style --foreground 244 "⚠ FluxGym directory already exists at: $INSTALL_DIR"
    if gum confirm --default=false "Do you want to delete it and clone fresh?"; then
        rm -rf "$INSTALL_DIR"
        if ! run_install_step "Cloning FluxGym repository" "git clone https://github.com/cocktailpeanut/fluxgym $INSTALL_DIR"; then
            exit 1
        fi
    else
        gum style --foreground 244 "Using existing installation..."
    fi
else
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$INSTALL_DIR")"
    if ! run_install_step "Cloning FluxGym repository" "git clone https://github.com/cocktailpeanut/fluxgym $INSTALL_DIR"; then
        exit 1
    fi
fi
echo ""

# Step 3: Clone sd-scripts into fluxgym
gum style --foreground 212 --bold "Step 3/11: Clone sd-scripts Repository"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ -d "$INSTALL_DIR/sd-scripts" ]]; then
    gum style --foreground 244 "⚠ sd-scripts directory already exists"
    gum style --foreground 244 "Skipping clone..."
else
    if ! run_install_step "Cloning sd-scripts repository" "git clone -b sd3 https://github.com/kohya-ss/sd-scripts $INSTALL_DIR/sd-scripts"; then
        exit 1
    fi
fi
echo ""

# Step 4: Create virtual environment with Python 3.10
gum style --foreground 212 --bold "Step 4/11: Create Virtual Environment"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cd "$INSTALL_DIR"
if [[ -d "$INSTALL_DIR/env" ]]; then
    gum style --foreground 244 "⚠ Virtual environment already exists"
    gum style --foreground 244 "Using existing environment..."
else
    if ! run_install_step "Creating Python 3.10 virtual environment" "python3.10 -m venv $INSTALL_DIR/env"; then
        exit 1
    fi
fi
echo ""

# Step 5: Activate virtual environment
gum style --foreground 212 --bold "Step 5/11: Activate Virtual Environment"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

gum style --foreground 212 "→ Activating virtual environment..."

# Use source in a subshell to activate and check
if source "$INSTALL_DIR/env/bin/activate" 2>&1; then
    if command -v python &>/dev/null && [[ "$(python --version 2>&1)" == *"3.10"* ]]; then
        gum style --foreground 40 "✓ Virtual environment activated successfully"
        gum style --foreground 242 "Python: $(python --version)"
    else
        gum style --foreground 1 --bold "✗ Virtual environment activation failed - Python not found in venv"
        exit 1
    fi
else
    gum style --foreground 1 --bold "✗ Failed to activate virtual environment"
    exit 1
fi
echo ""

# Step 6: Create temporary directory
gum style --foreground 212 --bold "Step 6/11: Setup Temporary Directory"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ! -d "$INSTALL_DIR/env/tmp" ]]; then
    mkdir -p "$INSTALL_DIR/env/tmp"
    gum style --foreground 40 "✓ Temporary directory created"
else
    gum style --foreground 244 "⚠ Temporary directory already exists"
fi
export TMPDIR="$INSTALL_DIR/env/tmp"
gum style --foreground 40 "✓ TMPDIR set to: $TMPDIR"
echo ""

# Step 7: Upgrade pip
gum style --foreground 212 --bold "Step 7/11: Upgrade pip"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! run_install_step "Upgrading pip" "python -m pip install --upgrade pip"; then
    exit 1
fi
echo ""

# Step 8: Install sd-scripts dependencies
gum style --foreground 212 --bold "Step 8/11: Install sd-scripts Dependencies"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! run_install_step "Installing sd-scripts requirements" \
    "cd $INSTALL_DIR/sd-scripts && pip install -r requirements.txt"; then
    exit 1
fi
echo ""

# Step 9: Install FluxGym dependencies
gum style --foreground 212 --bold "Step 9/11: Install FluxGym Dependencies"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! run_install_step "Installing FluxGym requirements" \
    "cd $INSTALL_DIR && pip install -r requirements.txt"; then
    exit 1
fi
echo ""

# Step 10: Install PyTorch with selected CUDA version
gum style --foreground 212 --bold "Step 10/11: Install PyTorch"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Convert CUDA version to wheel index format (e.g., 12.1 -> cu121)
CUDA_WHEEL=$(echo "$CUDA_VERSION" | sed 's/\.//g')

if ! run_install_step "Installing PyTorch with CUDA $CUDA_VERSION" \
    "pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu${CUDA_WHEEL}"; then
    exit 1
fi
echo ""

# Step 11: Install/Update bitsandbytes if CUDA 12.8 (for RTX 50-series)
if [[ "$CUDA_VERSION" == "12.8" ]]; then
    gum style --foreground 212 --bold "Step 11/11: Update bitsandbytes for RTX 50-series"
    gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if ! run_install_step "Updating bitsandbytes" \
        "pip install -U bitsandbytes"; then
        exit 1
    fi
    echo ""
    FINAL_STEP="Desktop Integration"
else
    FINAL_STEP="Desktop Integration"
fi

# Final Step: Create desktop integration
gum style --foreground 212 --bold "Step 10/10: $FINAL_STEP"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Copy launch script if available
cd "$ORIGINAL_DIR"
if [[ -f "$LAUNCH_SCRIPT_SRC" ]]; then
    mkdir -p "$(dirname "$LAUNCH_SCRIPT_DEST")"
    cp "$LAUNCH_SCRIPT_SRC" "$LAUNCH_SCRIPT_DEST"
    chmod +x "$LAUNCH_SCRIPT_DEST"
    gum style --foreground 40 "✓ Launch script installed"
    EXEC_CMD="$LAUNCH_SCRIPT_DEST"
else
    gum style --foreground 244 "⚠ Launch script not found in scripts/"
    EXEC_CMD="bash -c 'cd $INSTALL_DIR && source env/bin/activate && python app.py'"
fi
echo ""

# Create directories for desktop integration
mkdir -p "$(dirname "$DESKTOP_FILE")"
mkdir -p "$(dirname "$ICON_PATH")"

# Copy icon if available
if [[ -f "$INSTALL_DIR/icon.png" ]]; then
    cp "$INSTALL_DIR/icon.png" "$ICON_PATH"
    gum style --foreground 40 "✓ Icon installed"
else
    gum style --foreground 244 "⚠ Icon file not found in assets/"
    ICON_PATH=""
fi
echo ""

# Create desktop file
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Name=FluxGym
Comment=Flux model training GUI
Exec=$EXEC_CMD
Terminal=true
Type=Application
Icon=$ICON_PATH
StartupNotify=true
Categories=Development;Graphics;
EOF

chmod +x "$DESKTOP_FILE"
gum style --foreground 40 "✓ Desktop file created"
echo ""

# Installation Summary
echo ""
gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gum style --foreground 40 --bold "✓ FluxGym Installation Completed Successfully!"
gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

gum style --foreground 212 --bold "Installation Summary:"
echo ""
gum style --foreground 40 "Install Location: $INSTALL_DIR"
gum style --foreground 40 "Python Version: 3.10"
gum style --foreground 40 "Virtual Environment: $INSTALL_DIR/env"
gum style --foreground 40 "PyTorch Version: (CUDA $CUDA_VERSION)"
gum style --foreground 40 "Desktop File: $DESKTOP_FILE"
if [[ "$CUDA_VERSION" == "12.8" ]]; then
    gum style --foreground 40 "GPU Support: RTX 50-series optimized"
fi
echo ""

gum style --foreground 212 "You can now start FluxGym by:"
gum style --foreground 212 "1. Using the desktop application (FluxGym)"
gum style --foreground 212 "2. Running: cd $INSTALL_DIR && source env/bin/activate && python app.py"
gum style --foreground 212 "3. Or directly: $LAUNCH_SCRIPT_DEST (if available)"
echo ""

gum style --foreground 242 "Repository: https://github.com/cocktailpeanut/fluxgym"
echo ""

cd "$ORIGINAL_DIR"