#!/bin/bash
set -euo pipefail

ICON_DIR="$HOME/.local/share/applications/icons"
DESKTOP_DIR="$HOME/.local/share/applications/"

apps_to_remove=(
  "1password-beta"
  "1password-cli"
  "xournalpp"
  "signal-desktop"
  "typora"
)

web_apps_to_remove=(
  "Basecamp"
  "Figma"
  "HEY"
)

# Ensure gum is available (install on Arch if missing)
if ! command -v gum &>/dev/null; then
  echo "gum not found. Installing gum..."
  sudo pacman -S --noconfirm --needed gum || {
    echo "Failed to install gum. Please install it manually and re-run this script."
    exit 1
  }
fi

# Select regular apps to remove
selected_apps=$(gum choose --no-limit --height=10 --header "Select applications to remove (space to toggle, Enter to confirm):" \
  "${apps_to_remove[@]}") || true

if [[ -n "${selected_apps:-}" ]]; then
  echo "You selected the following applications for removal:"
  printf '  %s\n' $selected_apps

  if gum confirm --default-true "Proceed to remove the selected applications?"; then
    # mapfile to get newline-separated selections into array
    mapfile -t sel_apps_array <<<"$selected_apps"
    for app in "${sel_apps_array[@]}"; do
      echo "Removing $app..."
      if yay -R --noconfirm "$app" &>/dev/null; then
        echo "Removed $app"
      else
        echo "Warning: Could not remove $app (may not be installed or removal failed)"
      fi
    done
  else
    echo "Skipped removing applications."
  fi
else
  echo "No applications selected for removal."
fi

# Select web apps to remove
selected_web_apps=$(gum choose --no-limit --height=8 --header "Select web applications to remove (space to toggle, Enter to confirm):" \
  "${web_apps_to_remove[@]}") || true

if [[ -n "${selected_web_apps:-}" ]]; then
  echo "You selected the following web apps for removal:"
  printf '  %s\n' $selected_web_apps

  if gum confirm --default-true "Proceed to remove the selected web apps (desktop entries and icons)?"; then
    mapfile -t sel_web_array <<<"$selected_web_apps"
    for web in "${sel_web_array[@]}"; do
      echo "Removing desktop entry and icon for $web..."
      rm -f "$DESKTOP_DIR/${web}.desktop" "$ICON_DIR/${web}.png"
      echo "Removed files for $web (if present)."
    done
  else
    echo "Skipped removing web apps."
  fi
else
  echo "No web applications selected for removal."
fi

echo "Removal operations complete."