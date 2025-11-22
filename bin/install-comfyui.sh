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

# Ensure anaconda/conda is installed
if ! command -v conda &>/dev/null; then
    gum style --foreground 1 "Error: Anaconda/Conda is not installed. Installing now..."
    yay -S --noconfirm --needed anaconda|| {
        gum style --foreground 1 "Failed to install Anaconda/Conda. Please install it manually."
        exit 1
    }
fi

# Display installation header
gum style --foreground 212 --bold "ComfyUI Installation"
echo ""
gum style --foreground 242 "This script will install ComfyUI and configure it for your GPU."
echo ""

# Clone ComfyUI repository
gum style --foreground 212 --bold "→ Cloning ComfyUI repository..."
if git clone https://github.com/comfyanonymous/ComfyUI.git; then
    gum style --foreground 40 "✓ ComfyUI repository cloned successfully"
else
    gum style --foreground 1 --bold "✗ Failed to clone ComfyUI repository"
    exit 1
fi

echo ""

# Ask user to select GPU
gum style --foreground 212 --bold "→ GPU Selection"
gum style "Please select your GPU type:"
echo ""

gpu_choice=$(gum choose \
    "NVIDIA" \
    "AMD")

if [[ -z "$gpu_choice" ]]; then
    gum style --foreground 1 "✗ No GPU selected. Exiting installation."
    exit 1
fi

echo ""
gum style --foreground 212 "Selected GPU: $gpu_choice"
echo ""

# Create temp file for output
output_file=$(mktemp)

# Install PyTorch based on GPU selection
gum style --foreground 212 --bold "→ Installing PyTorch..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

case "$gpu_choice" in
    "NVIDIA")
        gum style "Installing PyTorch for NVIDIA GPU (CUDA 12.1)..."
        echo ""
        
        if conda install pytorch torchvision torchaudio pytorch-cuda=12.1 -c pytorch -c nvidia > "$output_file" 2>&1 &
        then
            pid=$!
            tail -f "$output_file" &
            tail_pid=$!
            
            if wait $pid 2>/dev/null; then
                kill $tail_pid 2>/dev/null || true
                wait $tail_pid 2>/dev/null || true
                echo ""
                gum style --foreground 40 "✓ PyTorch for NVIDIA installed successfully"
            else
                kill $tail_pid 2>/dev/null || true
                wait $tail_pid 2>/dev/null || true
                echo ""
                gum style --foreground 1 --bold "✗ Failed to install PyTorch for NVIDIA"
                rm -f "$output_file"
                exit 1
            fi
        fi
        ;;
    "AMD")
        gum style "Installing PyTorch for AMD GPU (ROCm 6.0)..."
        echo ""
        
        if pip3 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.0 > "$output_file" 2>&1 &
        then
            pid=$!
            tail -f "$output_file" &
            tail_pid=$!
            
            if wait $pid 2>/dev/null; then
                kill $tail_pid 2>/dev/null || true
                wait $tail_pid 2>/dev/null || true
                echo ""
                gum style --foreground 40 "✓ PyTorch for AMD installed successfully"
            else
                kill $tail_pid 2>/dev/null || true
                wait $tail_pid 2>/dev/null || true
                echo ""
                gum style --foreground 1 --bold "✗ Failed to install PyTorch for AMD"
                rm -f "$output_file"
                exit 1
            fi
        fi
        ;;
esac

echo ""

# Install ComfyUI dependencies
gum style --foreground 212 --bold "→ Installing ComfyUI dependencies..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if cd ComfyUI; then
    if pip install -r requirements.txt > "$output_file" 2>&1 &
    then
        pid=$!
        tail -f "$output_file" &
        tail_pid=$!
        
        if wait $pid 2>/dev/null; then
            kill $tail_pid 2>/dev/null || true
            wait $tail_pid 2>/dev/null || true
            echo ""
            gum style --foreground 40 "✓ ComfyUI dependencies installed successfully"
        else
            kill $tail_pid 2>/dev/null || true
            wait $tail_pid 2>/dev/null || true
            echo ""
            gum style --foreground 1 --bold "✗ Failed to install ComfyUI dependencies"
            rm -f "$output_file"
            exit 1
        fi
    fi
else
    gum style --foreground 1 --bold "✗ Failed to enter ComfyUI directory"
    rm -f "$output_file"
    exit 1
fi

# Clean up
rm -f "$output_file"

# Success message
echo ""
gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gum style --foreground 40 --bold "✓ ComfyUI installation completed successfully!"
echo ""
gum style --foreground 40 "You can now start ComfyUI by running:"
gum style --foreground 212 "  cd ComfyUI"
gum style --foreground 212 "  python main.py"
echo ""