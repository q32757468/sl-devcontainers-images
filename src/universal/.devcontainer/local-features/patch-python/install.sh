#!/usr/bin/env bash
set -e

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Patching Python pip registry mirrors..."

REMOTE_USER_HOME="$(get_remote_user_home)"

# pip mirror (Tsinghua)
mkdir -p "${REMOTE_USER_HOME}/.config/pip"
cat > "${REMOTE_USER_HOME}/.config/pip/pip.conf" << 'EOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${REMOTE_USER_HOME}/.config/pip"

echo "Done!"
