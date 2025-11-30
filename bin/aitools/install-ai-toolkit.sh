#!/bin/bash

set -u

ORIGINAL_DIR=$(pwd)
INSTALL_DIR="$HOME/ai-toolkit"
DESKTOP_FILE="$HOME/.local/share/applications/AI-Toolkit.desktop"
ICON_PATH="$HOME/.local/share/applications/icons/ai-toolkit.png"
CUDA_VERSION="12.6"

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
        DESKTOP_FILE="$HOME/.local/share/applications/AI-Toolkit.desktop"
        ICON_PATH="$HOME/.local/share/applications/icons/ai-toolkit.png"
        gum style --foreground 40 "✓ Installation directory set to: $INSTALL_DIR"
        echo ""
        return 0
    else
        gum style --foreground 244 "Directory change cancelled. Trying again..."
        echo ""
        confirm_install_directory
    fi
}

# Function to confirm or change CUDA version
confirm_cuda_version() {
    gum style --foreground 212 --bold "CUDA Version Configuration"
    gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    gum style "Default CUDA version:"
    gum style --foreground 40 "  $CUDA_VERSION"
    echo ""
    
    gum style --foreground 242 "Common CUDA versions: 11.8, 12.1, 12.4, 12.6"
    echo ""
    
    if gum confirm --default=true "Do you want to use CUDA $CUDA_VERSION?"; then
        gum style --foreground 40 "✓ Using CUDA $CUDA_VERSION"
        echo ""
        return 0
    fi
    
    # Prompt for custom CUDA version
    echo ""
    gum style "Enter custom CUDA version (e.g., 11.8, 12.1, 12.4, 12.6):"
    custom_cuda=$(gum input --placeholder "$CUDA_VERSION")
    
    if [[ -z "$custom_cuda" ]]; then
        gum style --foreground 244 "No input provided. Using CUDA $CUDA_VERSION."
        echo ""
        return 0
    fi
    
    # Validate CUDA version format (should be X.Y where X and Y are numbers)
    if ! [[ "$custom_cuda" =~ ^[0-9]+\.[0-9]+$ ]]; then
        gum style --foreground 1 "✗ Invalid CUDA version format. Please use format: X.Y (e.g., 12.6)"
        echo ""
        confirm_cuda_version
        return
    fi
    
    gum style --foreground 212 "New CUDA version:"
    gum style --foreground 40 "  $custom_cuda"
    echo ""
    
    if gum confirm --default=true "Confirm this CUDA version?"; then
        CUDA_VERSION="$custom_cuda"
        gum style --foreground 40 "✓ CUDA version set to: $CUDA_VERSION"
        echo ""
        return 0
    else
        gum style --foreground 244 "CUDA version change cancelled. Trying again..."
        echo ""
        confirm_cuda_version
    fi
}

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

# ===== MAIN INSTALLATION FLOW =====

clear
gum style --foreground 212 --bold "AI Toolkit Installation"
echo ""
gum style --foreground 242 "This script will install the AI Toolkit with PyTorch and dependencies."
echo ""

# Step 0a: Confirm installation directory
confirm_install_directory

# Step 0b: Confirm CUDA version
confirm_cuda_version

# Step 1: Check if directory already exists
gum style --foreground 212 --bold "Step 1/6: Clone Repository"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ -d "$INSTALL_DIR" ]]; then
    gum style --foreground 244 "⚠ AI Toolkit directory already exists at: $INSTALL_DIR"
    if gum confirm --default=false "Do you want to update it with git pull?"; then
        if ! run_install_step "Updating AI Toolkit repository" "cd $INSTALL_DIR && git pull"; then
            exit 1
        fi
    else
        gum style --foreground 244 "Using existing installation..."
    fi
else
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$INSTALL_DIR")"
    if ! run_install_step "Cloning AI Toolkit repository" "git clone https://github.com/ostris/ai-toolkit.git $INSTALL_DIR"; then
        exit 1
    fi
fi
echo ""

# Step 2: Create virtual environment
gum style --foreground 212 --bold "Step 2/6: Create Virtual Environment"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ -d "$INSTALL_DIR/venv" ]]; then
    gum style --foreground 244 "⚠ Virtual environment already exists"
    gum style --foreground 244 "Using existing environment..."
else
    if ! run_install_step "Creating Python virtual environment" "python3 -m venv $INSTALL_DIR/venv"; then
        exit 1
    fi
fi
echo ""

# Step 3: Activate virtual environment and upgrade pip
gum style --foreground 212 --bold "Step 3/6: Setup Python Environment"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

source "$INSTALL_DIR/venv/bin/activate"
if ! run_install_step "Upgrading pip" "$INSTALL_DIR/venv/bin/python -m pip install --upgrade pip"; then
    exit 1
fi
echo ""

# Step 4: Install PyTorch with selected CUDA version
gum style --foreground 212 --bold "Step 4/6: Install PyTorch"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Convert CUDA version to wheel index format (e.g., 12.6 -> cu126)
CUDA_WHEEL=$(echo "$CUDA_VERSION" | sed 's/\.//g')

if ! run_install_step "Installing PyTorch 2.7.0 with CUDA $CUDA_VERSION" \
    "$INSTALL_DIR/venv/bin/pip3 install --no-cache-dir torch==2.7.0 torchvision==0.22.0 torchaudio==2.7.0 --index-url https://download.pytorch.org/whl/cu${CUDA_WHEEL}"; then
    exit 1
fi
echo ""

# Step 5: Install AI Toolkit dependencies
gum style --foreground 212 --bold "Step 5/6: Install Dependencies"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! run_install_step "Installing AI Toolkit requirements" \
    "cd $INSTALL_DIR && $INSTALL_DIR/venv/bin/pip3 install -r requirements.txt"; then
    exit 1
fi
echo ""

# Step 6: Create desktop integration
gum style --foreground 212 --bold "Step 6/6: Desktop Integration"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create directories
mkdir -p "$(dirname "$DESKTOP_FILE")"
mkdir -p "$(dirname "$ICON_PATH")"

# Copy icon if available
if [[ -f "$ORIGINAL_DIR/assets/ai-toolkit.png" ]]; then
    cp "$ORIGINAL_DIR/assets/ai-toolkit.png" "$ICON_PATH"
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
Name=AI Toolkit
Comment=Machine learning training toolkit
Exec=bash -c "source $INSTALL_DIR/venv/bin/activate && cd $INSTALL_DIR && python3 -m toolkit"
Terminal=true
Type=Application
Icon=$ICON_PATH
StartupNotify=true
Categories=Development;Science;
EOF

chmod +x "$DESKTOP_FILE"
gum style --foreground 40 "✓ Desktop file created at: $DESKTOP_FILE"
echo ""

# Installation Summary
echo ""
gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gum style --foreground 40 --bold "✓ AI Toolkit Installation Completed Successfully!"
gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

gum style --foreground 212 --bold "Installation Summary:"
echo ""
gum style --foreground 40 "Install Location: $INSTALL_DIR"
gum style --foreground 40 "Virtual Environment: $INSTALL_DIR/venv"
gum style --foreground 40 "PyTorch Version: 2.7.0 (CUDA $CUDA_VERSION)"
gum style --foreground 40 "Desktop File: $DESKTOP_FILE"
echo ""

gum style --foreground 212 "You can now start AI Toolkit by:"
gum style --foreground 212 "1. Using the desktop application (AI Toolkit)"
gum style --foreground 212 "2. Running: source $INSTALL_DIR/venv/bin/activate && cd $INSTALL_DIR && python3 -m toolkit"
gum style --foreground 212 "3. Or directly: $INSTALL_DIR/venv/bin/python3 -m toolkit"
echo ""

gum style --foreground 242 "Repository: https://github.com/ostris/ai-toolkit.git"
echo ""

cd "$ORIGINAL_DIR"