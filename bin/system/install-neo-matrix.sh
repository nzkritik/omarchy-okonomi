#!/bin/bash
set -euo pipefail

# Ensure gum is available (install on Arch if missing)
if ! command -v gum &>/dev/null; then
  echo "gum not found. Installing gum..."
  sudo pacman -S --noconfirm --needed gum
fi

# Install neo-matrix
gum style --foreground 212 --bold "Installing neo-matrix..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
yay -S --noconfirm --needed neo-matrix

# Verify installation
if ! command -v neo-matrix &>/dev/null; then
  gum spin --title "Verifying installation" -- sleep 0.1
  gum style --foreground 1 "✗ neo-matrix not found after install. Aborting."
  exit 1
fi

gum style --foreground 212 --bold "✓ neo-matrix installed successfully."
echo ""

# Ask user via gum if they want neo-matrix as default screensaver
if gum confirm --default=false "Do you want neo-matrix as your default screensaver?"; then
  SCREENSAVER_SCRIPT="$HOME/.local/share/omarchy/bin/omarchy-launch-screensaver"
  if [[ -f "$SCREENSAVER_SCRIPT" ]]; then
    # Backup with timestamp
    bak="${SCREENSAVER_SCRIPT}.$(date +%Y%m%d%H%M%S).bak"
    cp -a "$SCREENSAVER_SCRIPT" "$bak"
    gum style --foreground 242 "Backed up original to: $bak"
    
    # Count instances of the pattern to replace
    count=$(grep -c '^\s*-e\s\+omarchy-cmd-screensaver$' "$SCREENSAVER_SCRIPT" || echo "0")
    
    if [[ $count -gt 0 ]]; then
      # Replace all instances of the pattern
      # Pattern explanation:
      # - `^\s*` matches the start of line with any leading whitespace
      # - `-e\s\+omarchy-cmd-screensaver` matches the exact command
      # - `$` anchors to end of line
      sed -i 's/^\s*-e\s\+omarchy-cmd-screensaver$/    -e neo-matrix --async --shadingmode=1 --defaultbg --colormode=16/g' "$SCREENSAVER_SCRIPT"
      
      gum style --foreground 40 "✓ Set neo-matrix as default screensaver in omarchy-launch-screensaver."
      gum style --foreground 40 "  (Replaced $count instance(s))"
    else
      gum style --foreground 244 "⚠ No instances of 'omarchy-cmd-screensaver' found to replace."
    fi
  else
    gum style --foreground 1 "✗ Screensaver script not found at: $SCREENSAVER_SCRIPT"
  fi
else
  gum style --foreground 244 "Neo-matrix installed, but not set as the default screensaver."
  gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
fi

echo ""