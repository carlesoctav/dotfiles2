#!/bin/bash
set -e

# Force-install (undeletable) extensions in the Zen flatpak and lock the policy file with chattr +i.
# To edit again: sudo chattr -i "$POLICY_FILE".
# Restart Zen afterwards and check about:policies.

POLICY_DIR="$HOME/.local/share/flatpak/extension/app.zen_browser.zen.systemconfig/x86_64/stable/policies"
POLICY_FILE="$POLICY_DIR/policies.json"
AMO="https://addons.mozilla.org/firefox/downloads/latest"

mkdir -p "$POLICY_DIR"
[ -f "$POLICY_FILE" ] && sudo chattr -i "$POLICY_FILE"

cat > "$POLICY_FILE" <<EOF
{
  "policies": {
    "ExtensionSettings": {
      "{26b4f076-089c-4c69-8497-44b7e5c9faef}": {"installation_mode": "force_installed", "install_url": "$AMO/socialfocus/latest.xpi"},
      "tab-stash@condordes.net": {"installation_mode": "force_installed", "install_url": "$AMO/tab-stash/latest.xpi"},
      "{446900e4-71c2-419f-a6a7-df9c091e268b}": {"installation_mode": "force_installed", "install_url": "$AMO/bitwarden-password-manager/latest.xpi"},
      "uBlock0@raymondhill.net": {"installation_mode": "force_installed", "install_url": "$AMO/ublock-origin/latest.xpi"},
      "{74e326aa-c645-4495-9287-b6febc5565a7}": {"installation_mode": "force_installed", "install_url": "$AMO/competitive-companion/latest.xpi"},
      "contact@alphaxiv.org": {"installation_mode": "force_installed", "install_url": "$AMO/alphaxiv/latest.xpi"}
    }
  }
}
EOF

sudo chattr +i "$POLICY_FILE"
