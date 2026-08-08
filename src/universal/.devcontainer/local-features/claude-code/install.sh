#!/usr/bin/env bash
set -e

echo "(*) Installing Claude Code..."

FEATURE_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="/usr/local/share/devcontainer-features/claude-code"

install -d -m 0755 "${RUNTIME_DIR}"
install -m 0755 \
  "${FEATURE_DIR}/post-start.sh" \
  "${RUNTIME_DIR}/post-start.sh"

# Resolve container username (falls back to "codespace")
USERNAME="${USERNAME:-"${_REMOTE_USER:-"codespace"}"}"
USER_HOME=$(getent passwd "${USERNAME}" | cut -d: -f6)

# Feature install scripts run as root. Install the global package as the
# container user so that pnpm's node_modules stays writable after startup.
runuser -u "${USERNAME}" -- env \
  HOME="${USER_HOME}" \
  pnpm --config.minimumReleaseAge=0 --allow-build=@anthropic-ai/claude-code add -g @anthropic-ai/claude-code

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
