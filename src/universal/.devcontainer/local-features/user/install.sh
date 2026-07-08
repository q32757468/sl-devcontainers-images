#!/usr/bin/env bash
set -e

echo "(*) Creating non-root user..."

USERNAME="${USERNAME:-"${_REMOTE_USER:-"codespace"}"}"
USER_UID="${USERUID:-"1000"}"
USER_GID="${USERGID:-"1000"}"

# Remove default ubuntu user if present
if id "ubuntu" &>/dev/null; then
    echo "Deleting user 'ubuntu'..."
    userdel -f -r ubuntu
fi

# Create group if not exists
if ! getent group "${USER_GID}" &>/dev/null; then
    groupadd --gid "${USER_GID}" "${USERNAME}"
fi

# Create user if not exists
if ! id "${USERNAME}" &>/dev/null; then
    useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}"
fi

# Grant passwordless sudo
echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/${USERNAME}"
chmod 0440 "/etc/sudoers.d/${USERNAME}"

echo "Done!"
