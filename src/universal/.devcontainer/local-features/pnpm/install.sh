#!/usr/bin/env bash
set -e

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Installing pnpm..."

curl -fsSL https://get.pnpm.io/install.sh | SHELL="$(which bash)" bash -

chown -R "${_REMOTE_USER}" "${PNPM_HOME}"

# pnpm mirror
run_as_remote_user \
    PNPM_HOME="${PNPM_HOME}" \
    PATH="${PNPM_HOME}:${PATH}" \
    pnpm config set registry https://registry.npmmirror.com/

echo "Done!"
