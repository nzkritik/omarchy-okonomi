#!/bin/bash
set -euo pipefail

ORIGINAL_DIR=$(pwd)
REPO_URL="https://github.com/nzkritik/dotfiles"
REPO_NAME="dotfiles"

# Ensure gum is available (install on Arch if missing)
if ! command -v gum &>/dev/null; then
  echo "gum not found. Installing gum..."
  sudo pacman -S --noconfirm --needed gum
fi

# Install neo-matrix
echo "Installing neo-matrix..."
yay -S --noconfirm --needed neo-matrix

# Verify installation
if ! command -v neo-matrix &>/dev/null; then
  gum spin --title "Verifying installation" -- sleep 0.1
  gum error "neo-matrix not found after install. Aborting."
  exit 1
fi

gum style --foreground 212 --bold "neo-matrix installed successfully."

# Ask user via gum if they want neo-matrix as default screensaver
if gum confirm --default=false "Do you want neo-matrix as your default screensaver?"; then
  SCREENSAVER_SCRIPT="$HOME/.local/share/omarchy/bin/omarchy-launch-screensaver"
  if [[ -f "$SCREENSAVER_SCRIPT" ]]; then
    # Backup with timestamp
    bak="${SCREENSAVER_SCRIPT}.$(date +%Y%m%d%H%M%S).bak"
    cp -a "$SCREENSAVER_SCRIPT" "$bak"
    gum style --foreground 242 "Backed up original to: $bak"

    # Prefer an in-place replacement of the "-e omarchy-cmd-screensaver" argument.
    if grep -q "omarchy-cmd-screensaver" "$SCREENSAVER_SCRIPT"; then
      sed -i 's/-e[[:space:]]*omarchy-cmd-screensaver/-e neo-matrix -async --shadingmode=1 --defaultbg --colormode=16/g' "$SCREENSAVER_SCRIPT"
      gum style --foreground 40 "Replaced omarchy-cmd-screensaver with neo-matrix in $SCREENSAVER_SCRIPT"
    else
      # Fallback: try to copy a prepared script from dotfiles if available
      cd "$HOME"
      if [[ ! -d "$REPO_NAME" ]]; then
        git clone "$REPO_URL"
      fi
      NEW_SCRIPT="$HOME/$REPO_NAME/omarchy/omarchy-launch-screensaver"
      if [[ -f "$NEW_SCRIPT" ]]; then
        cp -a "$NEW_SCRIPT" "$SCREENSAVER_SCRIPT"
        chmod +x "$SCREENSAVER_SCRIPT"
        gum style --foreground 40 "Replaced $SCREENSAVER_SCRIPT with the version from dotfiles."
      else
        gum warn "Could not find pattern to replace and no replacement script in dotfiles. Manual edit required."
      fi
      cd "$ORIGINAL_DIR"
    fi
  else
    gum warn "omarchy-launch-screensaver not found at $SCREENSAVER_SCRIPT. Attempting to copy replacement from dotfiles."

    cd "$HOME"
    if [[ ! -d "$REPO_NAME" ]]; then
      git clone "$REPO_URL"
    fi
    NEW_SCRIPT="$HOME/$REPO_NAME/omarchy/omarchy-launch-screensaver"
    if [[ -f "$NEW_SCRIPT" ]]; then
      mkdir -p "$(dirname "$SCREENSAVER_SCRIPT")"
      cp -a "$NEW_SCRIPT" "$SCREENSAVER_SCRIPT"
      chmod +x "$SCREENSAVER_SCRIPT"
      gum style --foreground 40 "Copied replacement script to $SCREENSAVER_SCRIPT"
    else
      gum error "Replacement script not found in dotfiles. Please create or provide $SCREENSAVER_SCRIPT manually."
      cd "$ORIGINAL_DIR"
      exit 1
    fi
    cd "$ORIGINAL_DIR"
  fi
else
  gum style --foreground 244 "Skipping setting neo-matrix as default screensaver."
fi

# Return to original directory
cd "$ORIGINAL_DIR"