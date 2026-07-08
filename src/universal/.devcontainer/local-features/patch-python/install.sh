#!/usr/bin/env bash
set -e

echo "(*) Patching Python pip registry mirrors..."

USERNAME="${USERNAME:-"${_REMOTE_USER:-"codespace"}"}"
USER_HOME=$(getent passwd "${USERNAME}" | cut -d: -f6)

# pip mirror (Tsinghua)
mkdir -p "${USER_HOME}/.config/pip"
cat > "${USER_HOME}/.config/pip/pip.conf" << 'EOF'
[global]
index-url = https://pypi.tuna.tsinghua.edu.cn/simple
trusted-host = pypi.tuna.tsinghua.edu.cn
EOF

chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}/.config/pip"

echo "Done!"
