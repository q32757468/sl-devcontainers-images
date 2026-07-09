#!/usr/bin/env bash
set -e

echo "(*) Installing Codex..."

pnpm add -g @openai/codex

USERNAME="${USERNAME:-"${_REMOTE_USER:-"codespace"}"}"
USER_HOME=$(getent passwd "${USERNAME}" | cut -d: -f6)

# Pre-create .codex config directory with correct ownership
# Docker named volumes inherit permissions from the image layer on first mount
mkdir -p "${USER_HOME}/.codex"
cat > "${USER_HOME}/.codex/config.toml" << 'EOF'
approval_policy = "never"
sandbox_mode = "danger-full-access"
EOF
chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}/.codex"

echo "Done!"
