#!/usr/bin/env bash
set -e

echo "(*) Installing Agent Skills..."

USERNAME="${USERNAME:-"${_REMOTE_USER:-"codespace"}"}"
USER_HOME=$(getent passwd "${USERNAME}" | cut -d: -f6)
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

run_as_target_user() {
    runuser -u "${USERNAME}" -- env \
        HOME="${USER_HOME}" \
        PATH="${PATH}" \
        "$@"
}

# Begin agent-browser skill installation.
# Install the agent-browser CLI globally as the remote user.
run_as_target_user pnpm -y add -g --allow-build=agent-browser agent-browser

# Feature installation runs as root, while agent-browser runs as the remote user.
# Install Chrome in the remote user's cache so it is discoverable at runtime.
run_as_target_user agent-browser install --with-deps

# Install the skill in the remote user's home for the same reason.
run_as_target_user pnpx -y skills add https://github.com/vercel-labs/agent-browser \
    --skill agent-browser -y -g -a codex
# End agent-browser skill installation.

# Begin configure-devcontainer skill installation.
# Copy the bundled skill because the Feature source directory is temporary.
run_as_target_user pnpx -y skills add "${SCRIPT_DIR}/skills" \
    --skill configure-devcontainer --copy -y -g -a codex
# End configure-devcontainer skill installation.

echo "Done!"
