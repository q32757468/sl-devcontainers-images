#!/usr/bin/env bash
set -e

echo "(*) Installing Feature Utilities..."

FEATURE_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="/usr/local/share/devcontainer-features/utils"

install -d -m 0755 "${RUNTIME_DIR}"
install -m 0644 "${FEATURE_DIR}/utils.sh" "${RUNTIME_DIR}/utils.sh"

echo "Done!"
