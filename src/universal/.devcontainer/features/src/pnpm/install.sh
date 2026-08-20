#!/usr/bin/env bash
set -e

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Installing pnpm..."

install -d -m 0755 "${PNPM_HOME}"
npm install --global --prefix "${PNPM_HOME}" pnpm

chown -R "${_REMOTE_USER}" "${PNPM_HOME}"

# pnpm mirror
run_as_remote_user \
    PNPM_HOME="${PNPM_HOME}" \
    PATH="${PNPM_HOME}/bin:${PATH}" \
    pnpm config set registry https://registry.npmmirror.com/

echo "Done!"
