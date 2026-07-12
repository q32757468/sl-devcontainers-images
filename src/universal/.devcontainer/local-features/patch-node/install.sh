#!/usr/bin/env bash
set -e

echo "(*) Patching npm registry mirrors..."

USERNAME="${USERNAME:-"${_REMOTE_USER:-"codespace"}"}"
USER_HOME=$(getent passwd "${USERNAME}" | cut -d: -f6)

# npm mirror
runuser -u "${USERNAME}" -- env \
    HOME="${USER_HOME}" \
    PATH="${PATH}" \
    npm config set registry https://registry.npmmirror.com/

echo "Done!"
