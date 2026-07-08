#!/usr/bin/env bash
set -e

echo "(*) Patching Node.js registry mirrors..."

USERNAME="${USERNAME:-"${_REMOTE_USER:-"codespace"}"}"
USER_HOME=$(getent passwd "${USERNAME}" | cut -d: -f6)

# npm mirror
echo 'registry=https://registry.npmmirror.com/' > "${USER_HOME}/.npmrc"
chown "${USERNAME}:${USERNAME}" "${USER_HOME}/.npmrc"

echo "Done!"
