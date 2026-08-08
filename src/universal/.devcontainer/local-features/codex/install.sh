#!/usr/bin/env bash
set -e

echo "(*) Installing Codex..."

FEATURE_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUNTIME_DIR="/usr/local/share/devcontainer-features/codex"

install -d -m 0755 "${RUNTIME_DIR}"
install -m 0755 \
    "${FEATURE_DIR}/post-start.sh" \
    "${RUNTIME_DIR}/post-start.sh"

USERNAME="${USERNAME:-"${_REMOTE_USER:-"codespace"}"}"
USER_HOME=$(getent passwd "${USERNAME}" | cut -d: -f6)

# Feature install scripts run as root.  Install the global package as the
# container user so that pnpm's node_modules and its contents remain writable
# by that user after the container starts.
runuser -u "${USERNAME}" -- env \
    HOME="${USER_HOME}" \
    pnpm --config.minimumReleaseAge=0 add -g @openai/codex

# Pre-create .codex config directory with correct ownership
# Docker named volumes inherit permissions from the image layer on first mount
mkdir -p "${USER_HOME}/.codex"
cat > "${USER_HOME}/.codex/config.toml" << 'EOF'
approval_policy = "never"
sandbox_mode = "danger-full-access"
EOF
chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}/.codex"

echo "Done!"
