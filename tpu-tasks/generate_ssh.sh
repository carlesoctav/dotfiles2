#!/bin/bash

# Generate SSH keys and propagate to all TPU workers
# This enables inter-worker communication for multiprocess training

# Get TPU instance name from metadata
TPU_NAME=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/attributes/instance-id 2>/dev/null)

# Get zone from metadata
ZONE=$(curl -H "Metadata-Flavor: Google" http://metadata.google.internal/computeMetadata/v1/instance/zone 2>/dev/null | cut -d'/' -f4)

echo "Setting up SSH keys for TPU: $TPU_NAME in zone: $ZONE"

# Run SSH command to all workers to generate and propagate keys
gcloud compute tpus tpu-vm ssh "$TPU_NAME" --zone="$ZONE" --worker=all --command="echo 'SSH key setup complete'"

echo "Done! Workers can now SSH to each other."
