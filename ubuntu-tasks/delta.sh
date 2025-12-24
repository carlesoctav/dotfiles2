#!/bin/bash

set -e

echo "Installing git-delta..."

# Download the deb package
wget -O git-delta_0.18.2_amd64.deb https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_amd64.deb

# Install the package
sudo dpkg -i git-delta_0.18.2_amd64.deb

# Clean up
rm git-delta_0.18.2_amd64.deb

echo "git-delta installed successfully!"
echo "You can now use 'delta' command or configure it as your git pager."
