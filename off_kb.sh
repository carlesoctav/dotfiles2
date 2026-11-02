#!/usr/bin/env bash
#
# Toggle / Turn Off / Turn On internal laptop keyboard
# Supports KDE Plasma (Wayland) without root, with kernel unbind fallback.

set -euo pipefail

KEYBOARD_NAME="AT Translated Set 2 keyboard"
SERIO_PORT="serio0"

send_notify() {
    local msg="$1"
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -i input-keyboard "Laptop Keyboard" "$msg"
    fi
}

get_kwin_devices() {
    for dev in $(busctl --user tree org.kde.KWin 2>/dev/null | grep -o '/org/kde/KWin/InputDevice/event[0-9]*'); do
        local name
        name=$(busctl --user get-property org.kde.KWin "$dev" org.kde.KWin.InputDevice name 2>/dev/null || true)
        if echo "$name" | grep -qi "$KEYBOARD_NAME"; then
            echo "$dev"
        fi
    done
}

kwin_get_status() {
    local dev="$1"
    local raw
    raw=$(busctl --user get-property org.kde.KWin "$dev" org.kde.KWin.InputDevice enabled 2>/dev/null || echo "b false")
    if [[ "$raw" == *"true"* ]]; then
        echo "on"
    else
        echo "off"
    fi
}

kwin_set_enabled() {
    local dev="$1"
    local val="$2" # true or false
    busctl --user set-property org.kde.KWin "$dev" org.kde.KWin.InputDevice enabled b "$val"
}

is_kwin_available() {
    busctl --user status org.kde.KWin >/dev/null 2>&1
}

# Determine default action based on script name (defaults to toggle)
SCRIPT_NAME="$(basename "$0")"
if [[ "$SCRIPT_NAME" == *"on"* && "$SCRIPT_NAME" != *"off"* ]]; then
    DEFAULT_ACTION="on"
else
    DEFAULT_ACTION="toggle"
fi

ACTION="${1:-$DEFAULT_ACTION}"

USE_KERNEL=false
if [[ "${1:-}" == "--kernel" || "${2:-}" == "--kernel" ]]; then
    USE_KERNEL=true
fi

if [ "$USE_KERNEL" = false ] && is_kwin_available; then
    devices=$(get_kwin_devices)
    if [ -z "$devices" ]; then
        echo "Warning: No KWin input device found matching '$KEYBOARD_NAME'. Falling back to kernel driver."
        USE_KERNEL=true
    fi
fi

if [ "$USE_KERNEL" = false ] && is_kwin_available; then
    for dev in $devices; do
        curr_status=$(kwin_get_status "$dev")
        target_action="$ACTION"

        if [ "$target_action" = "toggle" ]; then
            if [ "$curr_status" = "on" ]; then
                target_action="off"
            else
                target_action="on"
            fi
        fi

        case "$target_action" in
            off)
                kwin_set_enabled "$dev" false
                echo "Laptop keyboard ($dev) turned OFF"
                send_notify "Disabled (OFF)"
                ;;
            on)
                kwin_set_enabled "$dev" true
                echo "Laptop keyboard ($dev) turned ON"
                send_notify "Enabled (ON)"
                ;;
            status)
                echo "Laptop keyboard ($dev) status: $curr_status"
                ;;
            *)
                echo "Usage: $0 [off|on|toggle|status] [--kernel]"
                exit 1
                ;;
        esac
    done
else
    # Kernel mode (sysfs)
    DRIVER_PATH="/sys/bus/serio/drivers/atkbd"
    is_bound() {
        [ -e "$DRIVER_PATH/$SERIO_PORT" ]
    }

    curr_status=$(is_bound && echo "on" || echo "off")
    target_action="$ACTION"

    if [ "$target_action" = "toggle" ]; then
        if [ "$curr_status" = "on" ]; then
            target_action="off"
        else
            target_action="on"
        fi
    fi

    case "$target_action" in
        off)
            if is_bound; then
                echo -n "$SERIO_PORT" | sudo tee "$DRIVER_PATH/unbind" >/dev/null
                echo "Laptop keyboard ($SERIO_PORT) unbound (OFF)"
                send_notify "Disabled (OFF - Kernel)"
            else
                echo "Laptop keyboard is already OFF"
            fi
            ;;
        on)
            if ! is_bound; then
                echo -n "$SERIO_PORT" | sudo tee "$DRIVER_PATH/bind" >/dev/null
                echo "Laptop keyboard ($SERIO_PORT) bound (ON)"
                send_notify "Enabled (ON - Kernel)"
            else
                echo "Laptop keyboard is already ON"
            fi
            ;;
        status)
            echo "Laptop keyboard ($SERIO_PORT) kernel status: $curr_status"
            ;;
        *)
            echo "Usage: $0 [off|on|toggle|status] [--kernel]"
            exit 1
            ;;
    esac
fi
