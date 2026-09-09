#!/usr/bin/env bash
set -euo pipefail

# Install IBM Plex fonts (Mono and Sans)
# Downloads from IBM Plex GitHub releases and installs to ~/.local/share/fonts/ibm-plex

FONT_DIR="${HOME}/.local/share/fonts/ibm-plex"
VERSION="1.1.0"
TEMP_DIR=$(mktemp -d)

trap 'rm -rf "${TEMP_DIR}"' EXIT

fonts=(
  "plex-mono:ibm-plex-mono"
  "plex-sans:ibm-plex-sans"
)

mkdir -p "${FONT_DIR}"

for entry in "${fonts[@]}"; do
  tag="${entry%%:*}"
  asset="${entry#*:}"
  url="https://github.com/IBM/plex/releases/download/%40ibm/${tag}%40${VERSION}/${asset}.zip"
  echo "Downloading ${asset}..."
  curl -fsSL "${url}" -o "${TEMP_DIR}/${asset}.zip"
  unzip -qo "${TEMP_DIR}/${asset}.zip" -d "${TEMP_DIR}/${asset}"
  find "${TEMP_DIR}/${asset}" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} "${FONT_DIR}/" \;
done

fc-cache -fv
echo "Done! IBM Plex fonts installed to ${FONT_DIR}"
echo "Verify with: fc-list | grep -i 'IBM Plex'"
