#!/bin/bash

# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Description:
# gcs_training.sh [gcs_bucket] [mount_path] [file_path]
# Mounts GCS bucket with aiml-training profile optimized for AI/ML workloads
# gcs_bucket: GCS bucket name (with or without gs://)
# mount_path: Local mount path
# file_path: Optional file path for cache prefill

set -e

# Check arguments
if [[ $# -lt 2 ]]; then
  echo "Usage: gcs_training.sh [gcs_bucket] [mount_path] [file_path]"
  echo "  gcs_bucket: GCS bucket name (with or without gs://)"
  echo "  mount_path: Local mount path"
  echo "  file_path: Optional file path for cache prefill"
  echo ""
  echo "Example: gcs_training.sh gs://my-training-data ~/training-data"
  exit 1
fi

DATASET_GCS_BUCKET=$1
MOUNT_PATH=$2
FILE_PATH=$3

# Remove gs:// prefix if present
if [[ "$DATASET_GCS_BUCKET" =~ gs:\/\/ ]] ; then
    DATASET_GCS_BUCKET="${DATASET_GCS_BUCKET/gs:\/\//}"
    echo "Removed gs:// from GCS bucket name, GCS bucket is $DATASET_GCS_BUCKET"
fi

# Unmount if already mounted
if [[ -d ${MOUNT_PATH} ]]; then
  echo "$MOUNT_PATH exists, checking if mounted..."
  if mountpoint -q $MOUNT_PATH; then
    echo "Unmounting $MOUNT_PATH..."
    fusermount -u $MOUNT_PATH
  fi
  # Clean up empty directory if it exists
  if [[ -z "$(ls -A $MOUNT_PATH)" ]]; then
    echo "Removing empty directory $MOUNT_PATH..."
    rm -rf $MOUNT_PATH
  fi
fi

mkdir -p $MOUNT_PATH

# see https://cloud.google.com/storage/docs/gcsfuse-cli for all configurable options of gcsfuse CLI
TIMESTAMP=$(date +%Y%m%d-%H%M)
LOG_FILE="$HOME/gcsfuse_training_$TIMESTAMP.json"

echo "Mounting $DATASET_GCS_BUCKET to $MOUNT_PATH with aiml-training profile..."
echo "Log file: $LOG_FILE"

# Mount with aiml-training profile
# This profile is optimized for AI/ML training workloads
gcsfuse --profile=aiml-training --implicit-dirs --log-severity=debug \
        --log-file="$LOG_FILE" "$DATASET_GCS_BUCKET" "$MOUNT_PATH"

if [[ $? -eq 0 ]]; then
  echo "Successfully mounted $DATASET_GCS_BUCKET to $MOUNT_PATH"
else
  echo "Failed to mount $DATASET_GCS_BUCKET"
  exit 1
fi

# Use ls to prefill the metadata cache: https://cloud.google.com/storage/docs/cloud-storage-fuse/performance#improve-first-time-reads
if [[ ! -z ${FILE_PATH} ]] ; then 
  echo "Prefilling cache for $FILE_PATH..."
  FILE_COUNT=$(ls -R $FILE_PATH 2>/dev/null | wc -l)
  echo "$FILE_COUNT files found in $FILE_PATH"
fi

echo "Mount complete!"
