#!/bin/bash

ORIGINAL_DIR=$(pwd)
INSTALL_DIR="$HOME/stable-diffusion-webui"

# Install gum if not present
if ! command -v gum &> /dev/null; then
    yay -S --noconfirm gum
fi

# Step 1: Check Python 3.10
gum style --foreground 212 "Step 1: Checking Python 3.10..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if ! command -v python3.10 &> /dev/null; then
    gum style --foreground 244 "⚠ Python 3.10 not found. Installing...(this may take a while)"
    yay -S --noconfirm --needed python310
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
gum style --foreground 40 "✓ Virtual environment created at $INSTALL_DIR/venv310"

# Step 4: Activate venv
gum style --foreground 212 "Step 4: Activating virtual environment..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
source "$INSTALL_DIR/venv310/bin/activate"
python3.10 -m pip install --upgrade pip setuptools wheel
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
    PIP_TORCH_URL="https://download.pytorch.org/whl/cu118"
elif [[ "$CUDA_VERSION" == "12.1" ]]; then
    PIP_TORCH_URL="https://download.pytorch.org/whl/cu121"
else
    PIP_TORCH_URL="https://download.pytorch.org/whl/cu126"
fi
gum spin --show-output --spinner dot --title "Installing PyTorch..." -- pip install torch torchvision torchaudio --index-url "$PIP_TORCH_URL"
gum style --foreground 40 "✓ PyTorch installed with CUDA $CUDA_VERSION support"
STARTVENV="source $INSTALL_DIR/venv310/bin/activate"
STARTAPP="python $INSTALL_DIR/stable-diffusion-webui/webui.py"

# Step 11: setup launcher
gum style --foreground 212 "Step 11: Setting up launcher..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Create launch script
LAUNCH_SCRIPT="$INSTALL_DIR/launch-automatic1111.sh"
cat > "$LAUNCH_SCRIPT" <<EOF
#!/bin/bash
# Launch script for Automatic1111 Stable Diffusion WebUI
# Activate virtual environment and start webui
# Install gum if not present
if ! command -v gum &> /dev/null; then
    yay -S --noconfirm gum
fi
gum style --foreground 212 --bold "Launching Automatic1111 Stable Diffusion WebUI..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
${STARTVENV}
gum style --foreground 212 "→ Starting WebUI..."
${STARTAPP}
EOF
chmod +x "$LAUNCH_SCRIPT"
gum style --foreground 40 "✓ Launch script created at $LAUNCH_SCRIPT"

# Step 12: Create desktop integration

DESKTOP_FILE="$HOME/.local/share/applications/sd-webui.desktop"
ICON_PATH="$HOME/.local/share/icons/sd-webui.png"

gum style --foreground 212 --bold "Step 12: Creating desktop integration"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# set EXEC_CMD
if [[ -f "$LAUNCH_SCRIPT" ]]; then
    chmod +x "$LAUNCH_SCRIPT"
    gum style --foreground 40 "✓ Launch script installed"
    EXEC_CMD="$LAUNCH_SCRIPT"
else
    gum style --foreground 244 "⚠ Launch script not found in repo"
    EXEC_CMD="$STARTVENV && $STARTAPP"
fi

# Create directories for desktop integration
mkdir -p "$(dirname "$DESKTOP_FILE")"
mkdir -p "$(dirname "$ICON_PATH")"

# Copy icon if available (assuming icon.png in repo root)
if [[ -f "$ORIGINAL_DIR/assets/automatic1111.png" ]]; then
    cp "$ORIGINAL_DIR/assets/automatic1111.png" "$ICON_PATH"
    gum style --foreground 40 "✓ Icon installed"
else
    gum style --foreground 244 "⚠ Icon file not found in repo"
    ICON_PATH=""
fi

# Create desktop file
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Name=Automatic1111
Comment=Automatic1111 Stable Diffusion WebUI
Exec=$EXEC_CMD
Terminal=true
Type=Application
Icon=$ICON_PATH
StartupNotify=true
Categories=Graphics;Development;
EOF

chmod +x "$DESKTOP_FILE"
gum style --foreground 40 "✓ Desktop file created"
echo ""