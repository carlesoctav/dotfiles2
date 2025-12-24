#!/bin/bash

# Install uv on all TPU workers

# Get TPU instance name from metadata
TPU_NAME=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/instance-id 2>/dev/null)

# Get zone from metadata
ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone 2>/dev/null | cut -d'/' -f4)

echo "Installing uv on all workers for TPU: $TPU_NAME in zone: $ZONE"

# Install uv on all workers
gcloud compute tpus tpu-vm ssh "$TPU_NAME" --zone="$ZONE" --worker=all --command="curl -LsSf https://astral.sh/uv/install.sh | sh"

echo "Done! uv installed on all workers."
