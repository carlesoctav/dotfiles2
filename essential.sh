#!/bin/bash
set -e

# main machine fedora
sudo dnf install -y git tmux stow neovim alacritty ripgrep fzf jq unzip gh


git config --global user.email "carlesoctavianus@tuta.io" 
git config --global user.name "carlesoctav"               

curl -LsSf https://astral.sh/uv/install.sh | sh
curl https://mise.run | sh
curl -fsSL https://opencode.ai/install | bash
