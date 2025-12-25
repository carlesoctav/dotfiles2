#!/bin/bash

# Install IBM Plex fonts (Mono and Sans)
# Downloads from Google Fonts and installs to ~/.local/share/fonts

set -e

FONT_DIR="$HOME/.local/share/fonts/ibm-plex"
TEMP_DIR=$(mktemp -d)

echo "Downloading IBM Plex fonts..."
curl -fsSL -o "$TEMP_DIR/ibm-plex.zip" \
    "https://fonts.google.com/download?family=IBM%20Plex%20Mono|IBM%20Plex%20Sans"

echo "Installing fonts..."
mkdir -p "$FONT_DIR"
unzip -o "$TEMP_DIR/ibm-plex.zip" -d "$FONT_DIR"

echo "Updating font cache..."
fc-cache -fv "$HOME/.local/share/fonts"

echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Done! IBM Plex Mono and Sans installed."
echo "Verify with: fc-list | grep -i 'IBM Plex'"
