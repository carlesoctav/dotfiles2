#!/usr/bin/env bash
set -euo pipefail

# Downloads and installs Zed fonts to ~/.local/share/fonts/zed
# Usage: ./zed_font.sh

install_fonts() {
    font_dir="${HOME}/.local/share/fonts/zed"
    mkdir -p "${font_dir}"

    tmpdir="$(mktemp -d)"
    trap 'rm -rf "${tmpdir}"' EXIT

    fonts=(
      "zed-app-fonts-1.2.0"
      "zed-mono-1.2.0"
      "zed-sans-1.2.0"
    )

    base_url="https://github.com/zed-industries/zed-fonts/releases/download/1.2.0"

    for font in "${fonts[@]}"; do
      printf 'Downloading %s...\n' "${font}"
      curl -fsSL "${base_url}/${font}.zip" -o "${tmpdir}/${font}.zip"
      unzip -qo "${tmpdir}/${font}.zip" -d "${tmpdir}/${font}"
      find "${tmpdir}/${font}" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec cp {} "${font_dir}/" \;
    done

    fc-cache -fv
    printf 'Zed fonts installed to %s\n' "${font_dir}"
}

install_fonts
