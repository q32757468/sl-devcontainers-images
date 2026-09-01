#!/usr/bin/env bash
set -e

echo "(*) Configuring persistent VS Code Server extensions..."

source /usr/local/share/devcontainer-features/utils/utils.sh

# The Feature entrypoint runs after persistent volumes are mounted but before
# VS Code Server can create a nonempty extensions directory. Only install the
# startup hook here; it will create the link at container startup.
install_lifecycle_script vscode entrypoint

# _REMOTE_USER is supplied while Features are installed but is not guaranteed
# to exist at runtime. Persist it so the entrypoint can create the link as the
# user that VS Code Server will run as, even when the container starts as root.
REMOTE_USER="${_REMOTE_USER:-codespace}"
printf '%s\n' "${REMOTE_USER}" \
    >/usr/local/share/devcontainer-features/vscode/remote-user

echo "Done!"
