#!/bin/bash
# Treesitter setup for Ubuntu/Debian
# Installs tree-sitter-cli and compiles parsers that may have version mismatches

set -e

# Ensure cargo is available
if ! command -v cargo &> /dev/null; then
    echo "cargo not found. Install rust first: ./rust.sh"
    exit 1
fi

# Install build dependencies
sudo apt-get update
sudo apt-get install -y build-essential git

# Install tree-sitter-cli (requires >= 0.26.1 for nvim-treesitter main branch)
echo "Installing tree-sitter-cli..."
cargo install tree-sitter-cli

# Add cargo bin to PATH for this session
export PATH="$HOME/.cargo/bin:$PATH"

# Verify version
echo "tree-sitter version: $(tree-sitter --version)"

# Create parser directory
mkdir -p ~/.local/share/nvim/site/parser

# Compile vim parser (fixes "tab" node mismatch with nvim-treesitter queries)
echo "Compiling vim parser..."
cd /tmp
rm -rf tree-sitter-vim
git clone --depth 1 https://github.com/tree-sitter-grammars/tree-sitter-vim.git
cd tree-sitter-vim
tree-sitter generate
cc -shared -o vim.so -fPIC -I./src src/parser.c src/scanner.c -O2
cp vim.so ~/.local/share/nvim/site/parser/
rm -rf /tmp/tree-sitter-vim

# Compile lua parser (fixes "tab" node mismatch)
echo "Compiling lua parser..."
cd /tmp
rm -rf tree-sitter-lua
git clone --depth 1 https://github.com/tree-sitter-grammars/tree-sitter-lua.git
cd tree-sitter-lua
tree-sitter generate
cc -shared -o lua.so -fPIC -I./src src/parser.c src/scanner.c -O2
cp lua.so ~/.local/share/nvim/site/parser/
rm -rf /tmp/tree-sitter-lua

# Compile python parser (fixes "except*" node mismatch)
echo "Compiling python parser..."
cd /tmp
rm -rf tree-sitter-python
git clone --depth 1 https://github.com/tree-sitter/tree-sitter-python.git
cd tree-sitter-python
tree-sitter generate
cc -shared -o python.so -fPIC -I./src src/parser.c src/scanner.c -O2
cp python.so ~/.local/share/nvim/site/parser/
rm -rf /tmp/tree-sitter-python

echo "Done! Restart Neovim for changes to take effect."
