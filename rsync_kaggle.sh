#!/bin/bash

# Exit on script error (except for the rsync command itself, which we handle)
set -u

# Default configuration
DEFAULT_REPO="/kaggle/working/llm"
DEFAULT_INTERVAL=30 # in minutes

# Parse arguments
REMOTE_REPO="${1:-$DEFAULT_REPO}"
SYNC_INTERVAL_MIN="${2:-$DEFAULT_INTERVAL}"

# Display help if requested
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    echo "Usage: $0 [remote_repo_path] [sync_interval_minutes]"
    echo "Example: $0 /kaggle/working/llm 60"
    echo "Defaults:"
    echo "  remote_repo_path:      $DEFAULT_REPO"
    echo "  sync_interval_minutes: $DEFAULT_INTERVAL"
    exit 0
fi

# Validate sync interval is a number
if ! [[ "$SYNC_INTERVAL_MIN" =~ ^[0-9]+$ ]]; then
    echo "❌ Error: Sync interval must be a positive integer (minutes)."
    exit 1
fi

# Extracted repo basename for local directory
REPO_BASENAME=$(basename "$REMOTE_REPO")

# Remote SSH Host (configured in ~/.ssh/config)
SSH_HOST="Kaggle"

echo "========================================================"
echo "          Kaggle Rsync Daemon Started"
echo "========================================================"
echo "Remote Source:       ${SSH_HOST}:${REMOTE_REPO}"
echo "Sync Interval:       ${SYNC_INTERVAL_MIN} minute(s)"
echo "Local Sync Target:   ~/personal/sync/<date>/${REPO_BASENAME}"
echo "Excluding:           .venv/, and patterns in remote .gitignore"
echo "========================================================"

# Convert interval to seconds for sleep
SLEEP_SECONDS=$((SYNC_INTERVAL_MIN * 60))

while true; do
    CURRENT_DATE=$(date +%Y-%m-%d)
    LOCAL_SYNC_DIR="$HOME/personal/sync/${CURRENT_DATE}/${REPO_BASENAME}"
    
    # Create local sync directory if it doesn't exist
    mkdir -p "$LOCAL_SYNC_DIR"
    
    echo "⏳ [$(date +%H:%M:%S)] Starting sync..."
    
    # Prepare paths (ensuring source has a trailing slash for rsync contents transfer)
    SRC_PATH="${REMOTE_REPO}"
    [[ "$SRC_PATH" != */ ]] && SRC_PATH="${SRC_PATH}/"
    
    DST_PATH="${LOCAL_SYNC_DIR}"
    [[ "$DST_PATH" != */ ]] && DST_PATH="${DST_PATH}/"
    
    # Execute rsync
    # --exclude='.venv/' is explicitly added
    # --filter=':- .gitignore' automatically respects remote/local .gitignore files
    if rsync -avz \
        --exclude='.venv/' \
        --filter=':- .gitignore' \
        -e ssh "${SSH_HOST}:${SRC_PATH}" "${DST_PATH}"; then
        echo "✅ [$(date +%H:%M:%S)] Sync completed successfully."
    else
        echo "❌ [$(date +%H:%M:%S)] Sync failed! Kaggle instance may be offline or unreachable."
    fi
    
    echo "💤 Sleeping for ${SYNC_INTERVAL_MIN} minute(s) before next sync..."
    sleep "$SLEEP_SECONDS"
done
