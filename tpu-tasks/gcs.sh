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
# gcs.sh [mode] [gcs_bucket] [mount_path] [file_path]
# mode: ro or write_only
# gcs_bucket: GCS bucket name (with or without gs://)
# mount_path: Local mount path
# file_path: Optional file path for cache prefill

set -e

# Check arguments
if [[ $# -lt 3 ]]; then
  echo "Usage: gcs.sh [mode] [gcs_bucket] [mount_path] [file_path]"
  echo "  mode: ro or write_only"
  echo "  gcs_bucket: GCS bucket name"
  echo "  mount_path: Local mount path"
  echo "  file_path: Optional file path for cache prefill"
  exit 1
fi

MODE=$1
DATASET_GCS_BUCKET=$2
MOUNT_PATH=$3
FILE_PATH=$4

if [[ "$MODE" != "ro" && "$MODE" != "write_only" ]]; then
  echo "Invalid mode: $MODE. Must be 'ro' or 'write_only'"
  exit 1
fi

if [[ "$DATASET_GCS_BUCKET" =~ gs:\/\/ ]] ; then
    DATASET_GCS_BUCKET="${DATASET_GCS_BUCKET/gs:\/\//}"
    echo "Removed gs:// from GCS bucket name, GCS bucket is $DATASET_GCS_BUCKET"
fi

if [[ -d ${MOUNT_PATH} ]]; then
  echo "$MOUNT_PATH exists, removing..."
  fusermount -u $MOUNT_PATH || rm -rf $MOUNT_PATH
fi

mkdir -p $MOUNT_PATH

# see https://cloud.google.com/storage/docs/gcsfuse-cli for all configurable options of gcsfuse CLI
TIMESTAMP=$(date +%Y%m%d-%H%M)

if [[ "$MODE" == "ro" ]]; then
  gcsfuse -o ro --implicit-dirs --log-severity=debug \
          --type-cache-max-size-mb=-1 --stat-cache-max-size-mb=-1 --kernel-list-cache-ttl-secs=-1 --metadata-cache-ttl-secs=-1 \
          --log-file=$HOME/gcsfuse_$TIMESTAMP.json "$DATASET_GCS_BUCKET" "$MOUNT_PATH"
else
  gcsfuse --implicit-dirs --log-severity=debug \
          --type-cache-max-size-mb=-1 --stat-cache-max-size-mb=-1 --kernel-list-cache-ttl-secs=-1 --metadata-cache-ttl-secs=-1 \
          --log-file=$HOME/gcsfuse_$TIMESTAMP.json "$DATASET_GCS_BUCKET" "$MOUNT_PATH"
fi

# Use ls to prefill the metadata cache: https://cloud.google.com/storage/docs/cloud-storage-fuse/performance#improve-first-time-reads
if [[ ! -z ${FILE_PATH} ]] ; then 
  FILE_COUNT=$(ls -R $FILE_PATH | wc -l)
  echo $FILE_COUNT files found in $FILE_PATH
fi