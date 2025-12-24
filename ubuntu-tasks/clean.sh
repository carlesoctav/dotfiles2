#!/bin/bash

echo "=== WSL Storage Cleanup ==="

echo "Cleaning user cache..."
rm -rf ~/.cache/*

echo "Cleaning temp files..."
rm -rf /tmp/* /var/tmp/* 2>/dev/null

echo "Cleaning apt cache (requires sudo)..."
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get autoremove -y

echo "Cleaning journal logs (requires sudo)..."
sudo journalctl --vacuum-time=3d

if command -v docker &> /dev/null; then
    echo "Cleaning Docker..."
    docker system prune -a --volumes -f
fi

echo ""
echo "=== Cleanup Complete ==="
df -h / | tail -1
du -sh ~ 2>/dev/null
echo ""
echo "Run clean_windows.ps1 in PowerShell (Admin) to compact the VHDX"
