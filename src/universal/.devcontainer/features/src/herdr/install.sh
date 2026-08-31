#!/usr/bin/env bash
set -euo pipefail

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Installing Herdr..."

INSTALL_DIR="/usr/local/share/herdr/bin"
INSTALL_SCRIPT_URL="https://herdr.dev/install.sh"
GITHUB_MIRROR="${GITHUBMIRROR}"

install -d -m 0755 -o "${_REMOTE_USER}" -g "${_REMOTE_USER}" "${INSTALL_DIR}"

INSTALL_SCRIPT="$(download_install_script_with_github_proxy \
    "${INSTALL_SCRIPT_URL}" "${GITHUB_MIRROR}")"
run_as_remote_user env HERDR_INSTALL_DIR="${INSTALL_DIR}" "${INSTALL_SCRIPT}"

run_as_remote_user "${INSTALL_DIR}/herdr" --version >/dev/null

echo "Done!"
