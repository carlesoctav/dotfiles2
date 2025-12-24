#!/usr/bin/env bash
# description: Install universal-ctags from source
set -euo pipefail

# Install build dependencies
sudo apt update
sudo apt install -y build-essential autoconf automake pkg-config

# Clone and build ctags
tmp_dir=$(mktemp -d)
cd "$tmp_dir"

git clone https://github.com/universal-ctags/ctags.git
cd ctags
./autogen.sh
./configure
make
sudo make install

# Cleanup
cd /
rm -rf "$tmp_dir"

echo "universal-ctags installed successfully"
