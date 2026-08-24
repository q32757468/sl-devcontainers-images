#!/usr/bin/env bash
set -e

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Installing Codex..."

install_lifecycle_script codex
REMOTE_USER_HOME="$(get_remote_user_home)"
link_persistent_directory config "${REMOTE_USER_HOME}/.codex"

# Feature install scripts run as root.  Install the global package as the
# remote user so that pnpm's node_modules and its contents remain writable
# by that user after the container starts.
run_as_remote_user \
    pnpm --config.minimumReleaseAge=0 add -g @openai/codex

run_as_remote_user tee "${REMOTE_USER_HOME}/.codex/config.toml" > /dev/null << 'EOF'
approval_policy = "never"
sandbox_mode = "danger-full-access"
EOF

echo "Done!"
