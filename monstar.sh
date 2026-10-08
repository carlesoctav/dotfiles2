#!/usr/bin/env bash
set -euo pipefail

# Install monstar (Wayland terminal) from GitHub releases into ~/.local
# Usage: ./monstar.sh [version]
#   version: release tag without 'v' prefix (e.g. 1.0.1). Defaults to latest.
#   Env override: MONSTAR_VERSION=1.0.1 ./monstar.sh

PREFIX="${HOME}/.local"
VERSION="${1:-${MONSTAR_VERSION:-}}"
TEMP_DIR=$(mktemp -d)

trap 'rm -rf "${TEMP_DIR}"' EXIT

if [ -z "${VERSION}" ]; then
  echo "Resolving latest monstar release..."
  VERSION=$(curl -fsSL https://api.github.com/repos/rockorager/monstar/releases/latest \
    | grep '"tag_name"' | sed -E 's/.*"v([^"]+)".*/\1/')
fi

if [ -z "${VERSION}" ]; then
  echo "Error: could not determine monstar version" >&2
  exit 1
fi

ARCHIVE="monstar-${VERSION}-x86_64-linux.tar.gz"
URL="https://github.com/rockorager/monstar/releases/download/v${VERSION}/${ARCHIVE}"

echo "Installing monstar ${VERSION} to ${PREFIX}..."
curl -fsSL "${URL}" -o "${TEMP_DIR}/${ARCHIVE}"
tar -xzf "${TEMP_DIR}/${ARCHIVE}" -C "${TEMP_DIR}"

mkdir -p "${PREFIX}"
cp -r "${TEMP_DIR}/monstar-${VERSION}-x86_64-linux/bin" \
      "${TEMP_DIR}/monstar-${VERSION}-x86_64-linux/share" \
      "${PREFIX}/"

"${PREFIX}/bin/monstar" --help > /dev/null
echo "Done! monstar ${VERSION} installed to ${PREFIX}/bin/monstar"

case ":${PATH}:" in
  *":${PREFIX}/bin:"*) ;;
  *) echo "Note: ${PREFIX}/bin is not on PATH. Add it with:"; echo "  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac
