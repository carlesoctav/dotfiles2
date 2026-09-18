#!/usr/bin/env bash
set -e

# Escalate to root if not already running as root
if [ "$EUID" -ne 0 ]; then
    echo "Requesting root privileges..."
    exec sudo "$0" "$@"
fi

HWDB_FILE="/etc/udev/hwdb.d/99-veikk-a30.hwdb"

echo "==> Creating hwdb rule at $HWDB_FILE..."
cat << 'RULE' > "$HWDB_FILE"
# VEIKK A30 resolution fix for libinput / KDE Wayland
evdev:input:b0003v2FEBp0002*
 EVDEV_ABS_00=::200
 EVDEV_ABS_01=::200
RULE

echo "==> Updating hardware database..."
systemd-hwdb update

echo "==> Reloading udev input rules..."
udevadm trigger /sys/class/input/event*

echo ""
echo "Successfully applied! If the cursor does not move immediately, unplug and replug the USB cable."
