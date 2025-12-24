#!/bin/bash

# vLLM TPU Installation Script
# This script installs vLLM with TPU support on Google Cloud TPU VMs

set -e  # Exit on any error

echo "=== vLLM TPU Installation Script ==="
echo "Starting installation process..."

# Check if we're in the right directory
if [ ! -f "pyproject.toml" ] || [ ! -d "vllm" ]; then
    echo "Error: This script must be run from the vLLM repository root directory"
    exit 1
fi

# Check Python version
python_version=$(python3 --version 2>&1 | awk '{print $2}' | cut -d. -f1,2)
required_version="3.11"
if [ "$(printf '%s\n' "$required_version" "$python_version" | sort -V | head -n1)" != "$required_version" ]; then
    echo "Error: Python 3.11+ is required. Current version: $python_version"
    exit 1
fi

echo "✓ Python version check passed: $python_version"

# Install system dependencies
echo "Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y \
    libopenblas-base \
    libopenmpi-dev \
    libomp-dev

echo "✓ System dependencies installed"

# Create virtual environment
echo "Creating virtual environment..."
if [ -d ".venv" ]; then
    echo "Virtual environment already exists, removing old one..."
    rm -rf .venv
fi

python3 -m venv .venv
source .venv/bin/activate

echo "✓ Virtual environment created and activated"

# Upgrade pip
echo "Upgrading pip..."
.venv/bin/python -m pip install --upgrade pip

# Install TPU requirements
echo "Installing TPU requirements..."
if [ ! -f "requirements/tpu.txt" ]; then
    echo "Error: requirements/tpu.txt not found"
    exit 1
fi

.venv/bin/pip install -r requirements/tpu.txt

echo "✓ TPU requirements installed"

# Build and install vLLM with TPU support
echo "Building vLLM with TPU support..."
echo "This may take several minutes..."

VLLM_TARGET_DEVICE="tpu" .venv/bin/python -m pip install -e .

echo "✓ vLLM built and installed with TPU support"

# Verify installation
echo "Verifying installation..."
.venv/bin/python -c "import vllm; print(f'vLLM version: {vllm.__version__}')"

echo ""
echo "=== Installation Complete! ==="
echo ""
echo "To use vLLM with TPU:"
echo "1. Activate the virtual environment: source .venv/bin/activate"
echo "2. Run your TPU inference scripts"
echo "3. Check examples in: examples/offline_inference/profiling_tpu/"
echo ""
echo "Virtual environment location: $(pwd)/.venv"
echo "Installation verified successfully!"