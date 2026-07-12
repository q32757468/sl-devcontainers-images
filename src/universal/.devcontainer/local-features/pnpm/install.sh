#!/usr/bin/env bash
set -e

echo "(*) Installing pnpm..."

curl -fsSL https://get.pnpm.io/install.sh | SHELL="$(which bash)" bash -

USERNAME="${USERNAME:-"${_REMOTE_USER:-"codespace"}"}"
USER_HOME=$(getent passwd "${USERNAME}" | cut -d: -f6)
chown -R "${USERNAME}" "${PNPM_HOME}"

# pnpm mirror
runuser -u "${USERNAME}" -- env \
    HOME="${USER_HOME}" \
    PNPM_HOME="${PNPM_HOME}" \
    PATH="${PNPM_HOME}:${PATH}" \
    pnpm config set registry https://registry.npmmirror.com/

echo "Done!"
