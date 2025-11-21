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

# Function to display usage
show_usage() {
    cat <<'USAGE'
Usage: omarchy-install-dev-env <language>

Supported languages:
  - ruby
  - python
  - node
  - go
  - rust
  - php
  - java
  - bun
  - laravel
  - symfony
  - elixir
  - phoenix
  - ocaml
  - dotnet
  - clojure

Examples:
  omarchy-install-dev-env ruby
  omarchy-install-dev-env python

USAGE
}

# Check if language parameter is provided
if [[ $# -lt 1 ]]; then
    gum style --foreground 1 "Error: No language specified"
    echo ""
    show_usage
    exit 1
fi

language="$1"

# List of supported languages   ruby|node|bun|go|laravel|symfony|php|python|elixir|phoenix|rust|java|ocaml|dotnet|clojure
supported_languages=("ruby" "python" "node" "go" "rust" "php" "java" "bun" "laravel" "symfony" "elixir" "phoenix" "ocaml" "dotnet" "clojure")

# Check if language is supported
if [[ ! " ${supported_languages[@]} " =~ " ${language} " ]]; then
    gum style --foreground 1 "Error: Unsupported language '$language'"
    echo ""
    show_usage
    exit 1
fi

# Display installation header
gum style --foreground 212 --bold "Development Environment Installation"
gum style --foreground 212 "Option: $language"
echo ""
gum style --foreground 212 --bold "→ Installing $language development environment..."
gum style --foreground 242 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run the omarchy-install-dev-env command
if omarchy-install-dev-env "$language"; then
    echo ""
    gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    gum style --foreground 40 --bold "✓ $language development environment installed successfully"
    echo ""
    exit 0
else
    exit_code=$?
    echo ""
    gum style --foreground 212 "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    gum style --foreground 1 --bold "✗ Failed to install $language development environment (exit code: $exit_code)"
    exit 1
fi