#!/bin/bash
set -e

# main machine fedora
sudo dnf install -y git tmux stow neovim alacritty ghostty ripgrep fzf jq unzip gh tree-sitter-cli gcc gcc-c++ make


git config --global user.email "carlesoctavianus@tuta.io" 
git config --global user.name "carlesoctav"               
git config --global push.recurseSubmodules on-demand
git config --global submodule.recurse true

curl -LsSf https://astral.sh/uv/install.sh | sh
curl https://mise.run | sh
curl -fsSL https://opencode.ai/install | bash
curl -fsSL https://antigravity.google/cli/install.sh | bash
curl -fsSL https://dev.meta.ai/install.sh | bash
curl -fsSL https://raw.githubusercontent.com/raine/aven/main/scripts/install | bash
curl -fsSL https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh | bash

./ibm_fonts.sh

