#!/usr/bin/env bash
set -e

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Installing Codex..."

install_lifecycle_script codex
REMOTE_USER_HOME="$(get_remote_user_home)"

# Feature install scripts run as root.  Install the global package as the
# remote user so that pnpm's node_modules and its contents remain writable
# by that user after the container starts.
run_as_remote_user \
    pnpm --config.minimumReleaseAge=0 add -g @openai/codex

# Pre-create .codex config directory with correct ownership
# Docker named volumes inherit permissions from the image layer on first mount
mkdir -p "${REMOTE_USER_HOME}/.codex"
cat > "${REMOTE_USER_HOME}/.codex/config.toml" << 'EOF'
approval_policy = "never"
sandbox_mode = "danger-full-access"
EOF
chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${REMOTE_USER_HOME}/.codex"

echo "Done!"
