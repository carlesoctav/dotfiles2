#!/usr/bin/env bash
set -e

# Escalate to root if not already running as root
if [ "$EUID" -ne 0 ]; then
    echo "Requesting root privileges..."
    exec sudo "$0" "$@"
fi

HWDB_FILE="/etc/udev/hwdb.d/99-veikk-a30.hwdb"

if [ -f "$HWDB_FILE" ]; then
    echo "==> Removing hwdb rule at $HWDB_FILE..."
    rm -f "$HWDB_FILE"
else
    echo "==> No hwdb rule at $HWDB_FILE (nothing to remove)."
fi

echo "==> Updating hardware database..."
systemd-hwdb update

echo "==> Reloading udev input rules..."
udevadm trigger /sys/class/input/event*

echo ""
echo "Successfully reverted! If the cursor does not move immediately, unplug and replug the USB cable."
