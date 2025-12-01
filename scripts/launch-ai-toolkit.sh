#!/bin/bash

set -u

TOOLKIT_DIR="/run/media/user16/Files/ai-toolkit"
VENV_ACTIVATE="$TOOLKIT_DIR/venv/bin/activate"

# Ensure gum is installed
if ! command -v gum &>/dev/null; then
    echo "gum not found. Installing gum..."
    sudo pacman -S --noconfirm --needed gum || {
        echo "Failed to install gum. Please install it manually."
        exit 1
    }
fi

# Function to run command step with output
run_step() {
    local step_name="$1"
    local command="$2"
    
    gum style --foreground 212 --bold "→ $step_name"
    gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Run command directly without tail to preserve color formatting
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

# ===== MAIN LAUNCH FLOW =====

clear
gum style --foreground 212 --bold "AI Toolkit Launcher"
echo ""
gum style --foreground 242 "Starting AI Toolkit with UI build..."
echo ""

# Step 1: Verify toolkit directory exists
gum style --foreground 212 --bold "Step 1/4: Verify Installation"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ! -d "$TOOLKIT_DIR" ]]; then
    gum style --foreground 1 --bold "✗ AI Toolkit directory not found!"
    gum style --foreground 242 "Expected location: $TOOLKIT_DIR"
    echo ""
    exit 1
fi

if [[ ! -f "$VENV_ACTIVATE" ]]; then
    gum style --foreground 1 --bold "✗ Virtual environment not found!"
    gum style --foreground 242 "Expected location: $VENV_ACTIVATE"
    echo ""
    exit 1
fi

gum style --foreground 40 "✓ AI Toolkit directory verified"
gum style --foreground 40 "✓ Virtual environment found"
echo ""

# Step 2: Activate virtual environment
gum style --foreground 212 --bold "Step 2/4: Activate Virtual Environment"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

source "$VENV_ACTIVATE"
if [[ $? -eq 0 ]]; then
    gum style --foreground 40 "✓ Virtual environment activated"
else
    gum style --foreground 1 --bold "✗ Failed to activate virtual environment"
    exit 1
fi
echo ""

# Step 3: Start AI Toolkit backend
gum style --foreground 212 --bold "Step 3/4: Start AI Toolkit Backend"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! run_step "Running AI Toolkit" "cd $TOOLKIT_DIR && python3 -m toolkit"; then
    echo ""
    gum style --foreground 1 "Note: AI Toolkit backend may have exited or is running in background."
    echo ""
fi

# Step 4: Build and start UI
gum style --foreground 212 --bold "Step 4/4: Build and Start UI"
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ! -d "$TOOLKIT_DIR/ui" ]]; then
    gum style --foreground 1 --bold "✗ UI directory not found!"
    gum style --foreground 242 "Expected location: $TOOLKIT_DIR/ui"
    echo ""
    exit 1
fi

if ! command -v npm &>/dev/null; then
    gum style --foreground 1 --bold "✗ npm not found!"
    gum style --foreground 242 "Please install Node.js and npm to build the UI."
    echo ""
    exit 1
fi

if ! run_step "Building and starting UI" "cd $TOOLKIT_DIR/ui && npm run build_and_start"; then
    exit 1
fi
echo ""

# Success message
echo ""
gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
gum style --foreground 40 --bold "✓ AI Toolkit launched successfully!"
gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

gum style --foreground 212 --bold "Launch Summary:"
echo ""
gum style --foreground 40 "Toolkit Directory: $TOOLKIT_DIR"
gum style --foreground 40 "Virtual Environment: $VENV_ACTIVATE"
gum style --foreground 40 "UI Location: $TOOLKIT_DIR/ui"
echo ""

gum style --foreground 242 "Both the backend and UI should now be running."
echo ""