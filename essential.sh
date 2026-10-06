#!/bin/bash
set -e

# main machine fedora
sudo dnf install -y git tmux stow neovim alacritty ripgrep fzf jq unzip gh
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub app.zen_browser.zen


git config --global user.email "carlesoctavianus@tuta.io" 
git config --global user.name "carlesoctav"               
git config --global push.recurseSubmodules on-demand
git config --global submodule.recurse true

curl -LsSf https://astral.sh/uv/install.sh | sh
curl -f https://zed.dev/install.sh | sh
curl https://mise.run | sh
curl -fsSL https://opencode.ai/install | bash
curl -fsSL https://dev.meta.ai/install.sh | bash
curl -fsSL https://antigravity.google/cli/install.sh | bash

./ibm_fonts.sh

