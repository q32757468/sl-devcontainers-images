#!/usr/bin/env bash
set -e

echo "(*) Installing pnpm..."

curl -fsSL https://get.pnpm.io/install.sh | SHELL="$(which bash)" bash -

USERNAME="${USERNAME:-"${_REMOTE_USER:-"codespace"}"}"
chown -R "${USERNAME}" "${PNPM_HOME}"

echo "Done!"
