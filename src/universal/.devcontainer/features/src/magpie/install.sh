#!/usr/bin/env bash
set -euo pipefail

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Installing Magpie..."

install_lifecycle_script magpie post-create
install_lifecycle_script magpie post-start

INSTALL_DIR="/usr/local/share/magpie/bin"

install -d -m 0755 -o "${_REMOTE_USER}" -g "${_REMOTE_USER}" "${INSTALL_DIR}"

run_as_remote_user env MAGPIE_BIN_DIR="${INSTALL_DIR}" \
    sh -c 'curl -fsSL https://usemagpie.ai/install.sh | sh -s -- --tui'

echo "Done!"
