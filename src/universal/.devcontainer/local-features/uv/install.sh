#!/usr/bin/env bash
set -e

echo "(*) Installing uv..."

export UV_INSTALL_DIR="/usr/local/share/uv"
export INSTALLER_NO_MODIFY_PATH=1
curl -LsSf https://astral.sh/uv/install.sh | sh

USERNAME="${USERNAME:-"${_REMOTE_USER:-"codespace"}"}"
chown -R "${USERNAME}" "${UV_INSTALL_DIR}"

echo "Done!"
