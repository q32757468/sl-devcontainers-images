#!/usr/bin/env bash
set -euo pipefail

# Establish the link before VS Code Server starts. Doing this from
# onCreateCommand is too late because the server may already have created
# extensions/extensions.json, which makes the native directory nonempty.
RUNTIME_DIR="/usr/local/share/devcontainer-features/vscode"
REMOTE_USER="$(<"${RUNTIME_DIR}/remote-user")"
REMOTE_USER_HOME="$(getent passwd "${REMOTE_USER}" | cut -d: -f6)"
LINKER="/usr/local/share/devcontainer-features/utils/link-persistent-directory.sh"

if [[ -z "${REMOTE_USER_HOME}" ]]; then
    echo "Remote user '${REMOTE_USER}' does not exist or has no home directory." >&2
    exit 1
fi

# Feature entrypoints run as the container user, which may or may not be the
# remote user. Avoid runuser when both identities already refer to the same UID.
if [[ "$(id -u)" == "$(id -u "${REMOTE_USER}")" ]]; then
    exec env HOME="${REMOTE_USER_HOME}" "${LINKER}" \
        cache .vscode-server/extensions
fi

if [[ "$(id -u)" != 0 ]]; then
    echo "VS Code persistence entrypoint must run as root or '${REMOTE_USER}'." >&2
    exit 1
fi

# When the container starts as root, drop privileges so the persistent cache
# and symlink are owned by the same user that runs VS Code Server.
exec runuser -u "${REMOTE_USER}" -- env \
    HOME="${REMOTE_USER_HOME}" \
    PATH="${PATH}" \
    "${LINKER}" cache .vscode-server/extensions
