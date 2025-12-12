#!/bin/bash

# Install gum if not present
if ! command -v gum &> /dev/null; then
    gum spin --spinner dot --title "Installing gum..." -- yay -S --noconfirm gum
fi

# Step 1: Check Python 3.10
gum style --foreground 212 "Step 1: Checking Python 3.10..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ! command -v python3.10 &> /dev/null; then
    gum style "Python 3.10 not found. Installing...(this may take a while)"
    yay -S --noconfirm --needed python310
    python3.10 --version
fi

# Step 2: Prompt for install path (default: ~/stable-diffusion-webui)
gum style --foreground 212 "Step 2: Setting install path..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
INSTALL_DIR=$(gum input --placeholder "~/stable-diffusion-webui" --value "~/stable-diffusion-webui")
INSTALL_DIR=${INSTALL_DIR:-~/stable-diffusion-webui}
mkdir -p "$INSTALL_DIR"

# Step 3: Create venv
gum style --foreground 212 "Step 3: Creating virtual environment..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
python3.10 -m venv "$INSTALL_DIR/venv310"

# Step 4: Activate venv
gum style --foreground 212 "Step 4: Activating virtual environment..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
source "$INSTALL_DIR/venv310/bin/activate"

# Step 5: Set TMPDIR
gum style --foreground 212 "Step 5: Setting temporary directory..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
export TMPDIR="$INSTALL_DIR/venv310/tmp"
mkdir -p "$TMPDIR"

# Step 6: Prompt for CUDA version
gum style --foreground 212 "Step 6: Selecting CUDA version..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
CUDA_VERSION=$(gum choose "11.8" "12.1" "12.8")
echo "Selected CUDA version: $CUDA_VERSION"

# Step 7: Clone repo
gum style --foreground 212 "Step 7: Cloning repository..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gum spin --spinner dot --title "Cloning stable-diffusion-webui..." -- git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$INSTALL_DIR/stable-diffusion-webui"

# Step 8: cd into repo
gum style --foreground 212 "Step 8: Entering repository directory..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd "$INSTALL_DIR/stable-diffusion-webui"

# Step 9: Install requirements
gum style --foreground 212 "Step 9: Installing requirements..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gum spin --spinner dot --title "Installing Python requirements..." -- pip install -r requirements.txt

gum style --foreground 10 "Installation complete. To run, activate venv and launch webui.py."
gum style --foreground 10 "Commands:"
gum style --foreground 10 "  source $INSTALL_DIR/venv310/bin/activate"
gum style --foreground 10 "  python $INSTALL_DIR/stable-diffusion-webui/webui.py --cuda $CUDA_VERSION"