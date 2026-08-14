#!/usr/bin/env bash
set -e

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Installing Claude Code..."

install_lifecycle_script claude-code
install_lifecycle_script claude-code post-create
REMOTE_USER_HOME="$(get_remote_user_home)"

# Feature install scripts run as root. Install the global package as the
# remote user so that pnpm's node_modules stays writable after startup.
run_as_remote_user \
    pnpm --config.minimumReleaseAge=0 --allow-build=@anthropic-ai/claude-code add -g @anthropic-ai/claude-code

# Pre-create .claude config directory with correct ownership
# Docker named volumes inherit permissions from the image layer on first mount
mkdir -p "${REMOTE_USER_HOME}/.claude"
chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${REMOTE_USER_HOME}/.claude"

# Write default user settings to skip onboarding
cat > "${REMOTE_USER_HOME}/.claude.json" << 'EOF'
{
  "shiftEnterKeyBindingInstalled": true,
  "hasCompletedOnboarding": true,
  "autoUpdates": false,
  "autoInstallIdeExtension": false
}
EOF
chown "${_REMOTE_USER}:${_REMOTE_USER}" "${REMOTE_USER_HOME}/.claude.json"

echo "Done!"
