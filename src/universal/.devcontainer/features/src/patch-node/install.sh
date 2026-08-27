#!/usr/bin/env bash
set -e

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Patching npm registry mirrors..."

# npm mirror for the user running the Feature installation (usually root).
# This is also available to npm commands run by later image-build steps.
printf "%s\n" "registry=https://registry.npmmirror.com/" > "${HOME}/.npmrc"

# npm mirror
run_as_remote_user \
    sh -c 'printf "%s\n" "registry=https://registry.npmmirror.com/" > "${HOME}/.npmrc"'

echo "Done!"
