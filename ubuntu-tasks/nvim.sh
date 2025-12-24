#!/bin/bash

# Download the latest Neovim AppImage
curl -o ./nvim.appimage -LO https://github.com/neovim/neovim/releases/download/v0.11.1/nvim-linux-x86_64.appimage 

# Make the AppImage executable
chmod +x nvim.appimage 

sudo mv ./nvim.appimage /usr/local/bin/nvim
nvim

