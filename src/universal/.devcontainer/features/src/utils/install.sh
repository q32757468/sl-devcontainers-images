#!/usr/bin/env bash
set -e

echo "(*) Installing Feature Utilities..."

FEATURE_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="/usr/local/share/devcontainer-features/utils"

install -d -m 0755 "${RUNTIME_DIR}"
install -m 0644 "${FEATURE_DIR}/utils.sh" "${RUNTIME_DIR}/utils.sh"
install -m 0755 "${FEATURE_DIR}/link-persistent-directory.sh" \
    "${RUNTIME_DIR}/link-persistent-directory.sh"

source "${RUNTIME_DIR}/utils.sh"
REMOTE_USER_HOME="$(get_remote_user_home)"
# Docker initializes a new named volume from the image's mount point, including
# its ownership. Only prepare the roots here; application directories are
# linked after the volumes are mounted by their onCreateCommand hooks.
run_as_remote_user mkdir -p \
    "${REMOTE_USER_HOME}/.sl-config" \
    "${REMOTE_USER_HOME}/.sl-cache"

echo "Done!"
