#!/usr/bin/env bash
set -e

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Patching Python pip registry mirrors..."

REMOTE_USER_HOME="$(get_remote_user_home)"

# pip mirror (Alibaba Cloud)
mkdir -p "${REMOTE_USER_HOME}/.config/pip"
cat > "${REMOTE_USER_HOME}/.config/pip/pip.conf" << 'EOF'
[global]
index-url = https://mirrors.aliyun.com/pypi/simple/
trusted-host = mirrors.aliyun.com
EOF

chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${REMOTE_USER_HOME}/.config/pip"

echo "Done!"
