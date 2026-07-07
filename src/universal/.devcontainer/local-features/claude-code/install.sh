#!/usr/bin/env bash
set -e

echo "(*) Installing Claude Code..."

# Install Claude Code globally via pnpm
pnpm --allow-build=@anthropic-ai/claude-code add -g @anthropic-ai/claude-code

# Resolve container username (falls back to "hsl")
USERNAME="${USERNAME:-"${_REMOTE_USER:-"hsl"}"}"
USER_HOME=$(getent passwd "${USERNAME}" | cut -d: -f6)

# Pre-create .claude config directory with correct ownership
# Docker named volumes inherit permissions from the image layer on first mount
mkdir -p "${USER_HOME}/.claude"
chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}/.claude"

# Write default user settings to skip onboarding
cat > "${USER_HOME}/.claude.json" << 'EOF'
{
  "shiftEnterKeyBindingInstalled": true,
  "hasCompletedOnboarding": true,
  "autoUpdates": false,
  "autoInstallIdeExtension": false
}
EOF
chown "${USERNAME}:${USERNAME}" "${USER_HOME}/.claude.json"

echo "Done!"
