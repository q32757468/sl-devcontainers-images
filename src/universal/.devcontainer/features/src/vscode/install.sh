#!/usr/bin/env bash
set -e

source /usr/local/share/devcontainer-features/utils/utils.sh

install_lifecycle_script vscode on-create

REMOTE_USER_HOME="$(get_remote_user_home)"
link_persistent_directory cache "${REMOTE_USER_HOME}/.vscode-server/extensions"
