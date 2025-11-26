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

# Function to detect GPU
detect_gpu() {
    local nvidia_gpus=()
    local amd_gpus=()
    local apple_gpus=()
    
    # Check for NVIDIA GPUs using nvidia-smi
    if command -v nvidia-smi &>/dev/null; then
        nvidia_gpus=($(nvidia-smi --query-gpu=index,name --format=csv,noheader 2>/dev/null | grep -v "Integrated" | awk '{print $1}'))
        if [[ ${#nvidia_gpus[@]} -eq 0 ]]; then
            nvidia_gpus=($(nvidia-smi --query-gpu=index,name --format=csv,noheader 2>/dev/null | awk '{print $1}'))
        fi
    fi
    
    # Check for AMD GPUs using rocm-smi
    if command -v rocm-smi &>/dev/null; then
        amd_gpus=($(rocm-smi --showproductname 2>/dev/null | grep -v "GPU" | awk '{print NR-1}'))
    fi
    
    # Fallback: Check for Apple Silicon
    if [[ $(uname -m) == "arm64" ]]; then
        apple_gpus=("Apple Silicon")
    fi
    
    # If no specific tools found, use lspci as fallback
    if [[ ${#nvidia_gpus[@]} -eq 0 && ${#amd_gpus[@]} -eq 0 && ${#apple_gpus[@]} -eq 0 ]]; then
        if command -v lspci &>/dev/null; then
            # Check for NVIDIA GPUs via lspci
            if lspci | grep -qi "nvidia\|geforce\|tesla"; then
                nvidia_gpus=("0")
            fi
            
            # Check for AMD GPUs via lspci
            if lspci | grep -qi "amd\|radeon"; then
                amd_gpus=("0")
            fi
        fi
    fi
    
    # Return results
    if [[ ${#nvidia_gpus[@]} -gt 0 ]]; then
        echo "NVIDIA:${nvidia_gpus[*]}"
    elif [[ ${#amd_gpus[@]} -gt 0 ]]; then
        echo "AMD:${amd_gpus[*]}"
    elif [[ ${#apple_gpus[@]} -gt 0 ]]; then
        echo "APPLE:${apple_gpus[*]}"
    else
        echo "NONE"
    fi
}

# Function to select GPU
select_gpu() {
    local gpu_info="$1"
    local gpu_type="${gpu_info%%:*}"
    local gpu_list="${gpu_info#*:}"
    
    if [[ "$gpu_type" == "NONE" ]]; then
        gum style --foreground 1 --bold "✗ No compatible GPU found!"
        gum style --foreground 242 "ComfyUI requires NVIDIA, AMD, or Apple Silicon GPU."
        exit 1
    fi
    
    gum style --foreground 212 --bold "→ GPU Detection"
    gum style "Detected GPU: $gpu_type"
    echo ""
    
    # If multiple discrete GPUs, ask user to select
    IFS=':' read -ra gpu_array <<< "$gpu_list"
    if [[ ${#gpu_array[@]} -gt 1 ]]; then
        gum style "Multiple GPUs detected. Please select the one to use:"
        local selected_gpu=$(gum choose "${gpu_array[@]}")
        echo "$gpu_type:$selected_gpu"
    else
        echo "$gpu_type:${gpu_array[0]}"
    fi
}

# Function to install conda if needed
ensure_conda() {
    if ! command -v conda &>/dev/null; then
        gum style --foreground 212 --bold "→ Installing Miniconda..."
        if yay -S --noconfirm --needed miniconda3; then
            gum style --foreground 40 "✓ Miniconda installed successfully"
        else
            gum style --foreground 1 --bold "✗ Failed to install Miniconda"
            exit 1
        fi
    else
        gum style --foreground 40 "✓ Conda is already installed"
    fi
    echo ""
}

# Function to run installation with output
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
gum style --foreground 212 --bold "ComfyUI Installation"
echo ""
gum style --foreground 242 "This script will install ComfyUI and configure it for your GPU."
echo ""

# Step 1: Detect GPU
gum style --foreground 212 --bold "Step 1/5: GPU Detection"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gpu_info=$(detect_gpu)
selected_gpu=$(select_gpu "$gpu_info")
gpu_type="${selected_gpu%%:*}"
gpu_device="${selected_gpu#*:}"
gum style --foreground 40 "✓ Selected GPU: $gpu_type ($gpu_device)"
echo ""

# Step 2: Ensure conda is installed
gum style --foreground 212 --bold "Step 2/5: Check Dependencies"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ensure_conda

# Step 3: Create virtual environment and clone repo
gum style --foreground 212 --bold "Step 3/5: Setup Virtual Environment"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Initialize conda for bash
if ! run_install_step "Initializing conda for bash" "conda init bash"; then
    exit 1
fi
echo ""

# Add TERMINFO environment variable to ~/.bashrc
if ! grep -q "export TERMINFO=" "$HOME/.bashrc"; then
    gum style --foreground 212 --bold "→ Configuring TERMINFO environment variable"
    gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo 'export TERMINFO="/usr/share/terminfo"' >> "$HOME/.bashrc"
    gum style --foreground 40 "✓ TERMINFO environment variable added to ~/.bashrc"
else
    gum style --foreground 212 --bold "→ Configuring TERMINFO environment variable"
    gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    gum style --foreground 244 "⚠ TERMINFO environment variable already exists in ~/.bashrc"
fi
echo ""

# Source conda initialization
source "$HOME/.bashrc"
echo ""

# Create conda environment
if ! run_install_step "Creating conda environment" "conda create -n comfyenv python=3.12 -y"; then
    exit 1
fi
echo ""

# Clone repository
cd ~
if ! run_install_step "Cloning ComfyUI repository" "git clone https://github.com/comfyanonymous/ComfyUI.git"; then
    exit 1
fi
echo ""
mkdir "$HOME/ComfyUI/tmp"
export TMPDIR="$HOME/ComfyUI/tmp"

# Step 4: Install GPU dependencies
gum style --foreground 212 --bold "Step 4/5: Installing GPU Dependencies"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

case "$gpu_type" in
    "NVIDIA")
        if ! run_install_step "Installing PyTorch for NVIDIA (CUDA 12.1)" "conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia -y"; then
            exit 1
        fi
        ;;
    "AMD")
        if ! run_install_step "Installing PyTorch for AMD (ROCm 6.0)" "pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0"; then
            exit 1
        fi
        ;;
    "APPLE")
        if ! run_install_step "Installing PyTorch for Apple Silicon" "conda install pytorch-nightly::pytorch torchvision torchaudio -c pytorch-nightly -y"; then
            exit 1
        fi
        ;;
esac
echo ""

# Install ComfyUI dependencies
if ! run_install_step "Installing ComfyUI dependencies" "cd ~/ComfyUI && pip install -r requirements.txt"; then
    exit 1
fi
echo ""

# Step 5: Setup desktop integration
gum style --foreground 212 --bold "Step 5/5: Desktop Integration"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Copy launch script
cd $ORIGINAL_DIR
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
cd $ORIGINAL_DIR
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
Exec=bash -c "cd \$HOME/ComfyUI && conda deactivate && conda activate comfyenv && python main.py"
Terminal=true
Type=Application
Icon=$ICON_PATH
StartupNotify=true
EOF

chmod +x "$DESKTOP_FILE"
gum style --foreground 40 "✓ Desktop file created"
echo ""

# Success message
echo ""
gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gum style --foreground 40 --bold "✓ ComfyUI installation completed successfully!"
echo ""
gum style --foreground 40 "GPU Type: $gpu_type"
gum style --foreground 40 "Installation Location: $HOME/ComfyUI"
echo ""
gum style --foreground 212 "You can now start ComfyUI by:"
gum style --foreground 212 "1. Using the desktop application (ComfyUI)"
gum style --foreground 212 "2. Running: cd ~/ComfyUI && conda activate comfyenv && python main.py"
echo ""

cd "$ORIGINAL_DIR"