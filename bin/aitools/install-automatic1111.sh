#!/bin/bash

ORIGINAL_DIR=$(pwd)
INSTALL_DIR="$HOME/stable-diffusion-webui"

# Install gum if not present
if ! command -v gum &> /dev/null; then
    gum spin --show-output --spinner dot --title "Installing gum..." -- yay -S --noconfirm gum
fi

# Step 1: Check Python 3.10
gum style --foreground 212 "Step 1: Checking Python 3.10..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ! command -v python3.10 &> /dev/null; then
    gum spin --show-output --spinner dot --title "Installing Python 3.10...(this may take a while)" -- yay -S --noconfirm --needed python310
    gum style --foreground 40 "✓ Python 3.10 installed"
else
    gum style --foreground 40 "✓ Python 3.10 is already installed"
    python3.10 --version
fi

# Step 2: Prompt for install path (default: ~/stable-diffusion-webui)
gum style --foreground 212 "Step 2: Setting install path..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
INSTALL_DIR=$(gum input --placeholder "$INSTALL_DIR" --value "$INSTALL_DIR")
mkdir -p "$INSTALL_DIR"
gum style --foreground 40 "✓ Install path set to: $INSTALL_DIR"

# Step 3: Create venv
gum style --foreground 212 "Step 3: Creating virtual environment..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
python3.10 -m venv "$INSTALL_DIR/venv310"
python3.10 -m pip install --upgrade pip setuptools wheel
gum style --foreground 40 "✓ Virtual environment created at $INSTALL_DIR/venv310"

# Step 4: Activate venv
gum style --foreground 212 "Step 4: Activating virtual environment..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
source "$INSTALL_DIR/venv310/bin/activate"
gum style --foreground 40 "✓ Virtual environment activated"

# Step 5: Set TMPDIR
gum style --foreground 212 "Step 5: Setting temporary directory..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
export TMPDIR="$INSTALL_DIR/venv310/tmp"
mkdir -p "$TMPDIR"
gum style --foreground 40 "✓ Temporary directory set to: $TMPDIR"

# Step 6: Prompt for CUDA version
gum style --foreground 212 "Step 6: Selecting CUDA version..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
CUDA_VERSION=$(gum choose "11.8" "12.1" "12.8")
gum style --foreground 40 "✓ Selected CUDA version: $CUDA_VERSION"

# Step 7: Clone repo
gum style --foreground 212 "Step 7: Cloning repository..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gum spin --show-output --spinner dot --title "Cloning stable-diffusion-webui..." -- git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$INSTALL_DIR/stable-diffusion-webui"
gum style --foreground 40 "✓ Repository cloned to $INSTALL_DIR/stable-diffusion-webui"

# Step 8: cd into repo
gum style --foreground 212 "Step 8: Entering repository directory..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$INSTALL_DIR/stable-diffusion-webui"

# Step 9: Install requirements
gum style --foreground 212 "Step 9: Installing requirements..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gum spin --show-output --spinner dot --title "Installing Python requirements..." -- pip install -r requirements.txt
gum style --foreground 40 "✓ Requirements installed"

# Step 10: Install PyTorch with selected CUDA version
gum style --foreground 212 "Step 10: Installing PyTorch with CUDA $CUDA_VERSION..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [[ "$CUDA_VERSION" == "11.8" ]]; then
    PIP_TORCH_URL="https://download.pytorch.org/whl/cu118
elif [[ "$CUDA_VERSION" == "12.1" ]]; then
    PIP_TORCH_URL="https://download.pytorch.org/whl/cu121
else
    PIP_TORCH_URL="https://download.pytorch.org/whl/cu128
fi
gum spin --show-output --spinner dot --title "Installing PyTorch..." -- pip install torch torchvision torchaudio --index-url "$PIP_TORCH_URL"
gum style --foreground 40 "✓ PyTorch installed with CUDA $CUDA_VERSION"

# Step 11: Final instructions
gum style --foreground 212 "Step 11: Finalizing installation..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$ORIGINAL_DIR"
gum style --foreground 10 "Installation complete. To run, activate venv and launch webui.py."
gum style --foreground 10 "Commands:"
gum style --foreground 10 "  source $INSTALL_DIR/venv310/bin/activate"
gum style --foreground 10 "  python $INSTALL_DIR/stable-diffusion-webui/webui.py --cuda $CUDA_VERSION"