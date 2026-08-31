#!/bin/bash
cd "$(dirname "$0")"

source test-utils.sh

# ------------------------------------------------------------------
# Basic system checks
# ------------------------------------------------------------------
check "non-root-user" id hsl
check "locale" bash -c "locale -a | grep -q C.utf8"
check "timezone" bash -c 'test "$(cat /etc/timezone)" = "Asia/Shanghai" && test "$(date +%z)" = "+0800"'
check "sudo" sudo echo "sudo works."
check "bash" bash --version

# System packages
checkOSPackages "system-packages" curl ca-certificates git sudo

# ------------------------------------------------------------------
# Feature smoke checks
# ------------------------------------------------------------------
check "node" node --version
check "npm" npm --version
check "nvm" bash -c ". /usr/local/share/nvm/nvm.sh && nvm --version"
check "pnpm" pnpm --version
check "gh" gh --version
check "codex" codex --version
check "herdr" herdr --version
check "agy" agy --version
check "claude" claude --version
check "agent-browser" agent-browser --version
check "python3" python3 --version
check "pip3" pip3 --version
check "uv" uv --version
check "rustc" rustc --version
check "cargo" cargo --version
check "rustup" rustup --version

# ------------------------------------------------------------------
# Cross-feature and final image integration checks
# ------------------------------------------------------------------
count=$(find /usr/local/share/nvm/versions/node -mindepth 1 -maxdepth 1 -type d | wc -l)
checkVersionCount "two-node-versions" "$count" 2
check "default-node-version" bash -c "node --version | grep -q '^v24\.'"
check "python-version" bash -c "python3 --version | grep -q '3\.12'"
check "remote-user-homes" bash -c '
    set -e
    test -z "${CARGO_HOME:-}"
    test -d "${HOME}/.cargo"
    test -d "${HOME}/.codex"
    test -d "${HOME}/.claude"
'
check "persistent-volume-links" bash -c '
    set -e
    test "$(readlink "${HOME}/.codex")" = "${HOME}/.sl-config/.codex"
    test "$(readlink "${HOME}/.claude")" = "${HOME}/.sl-config/.claude"
    test "$(readlink "${HOME}/.gemini")" = "${HOME}/.sl-config/.gemini"
    test "$(readlink "${HOME}/.cargo/registry")" = "${HOME}/.sl-cache/.cargo/registry"
'
check "codex-final-config" bash -c '
    set -e
    config="${HOME}/.codex/config.toml"
    test -f "$config"
    grep -Fxq "approval_policy = \"never\"" "$config"
    grep -Fxq "sandbox_mode = \"danger-full-access\"" "$config"
'
check "claude-lifecycle" bash -c '
    set -e
    test -f "${HOME}/.claude/settings.json"
    test -L "${HOME}/.claude/skills"
    test "$(readlink "${HOME}/.claude/skills")" = "${HOME}/.agents/skills"
    test "$(jq -r ".permissions.defaultMode" "${HOME}/.claude/settings.json")" = "bypassPermissions"
'
check "antigravity-yolo-config" bash -c '
    set -e
    settings="${HOME}/.gemini/antigravity-cli/settings.json"
    test -f "${settings}"
    test "$(jq -r ".agentMode" "${settings}")" = "accept-edits"
    test "$(jq -r ".toolPermission" "${settings}")" = "always-proceed"
    test "$(jq -r ".artifactReviewPolicy" "${settings}")" = "always-proceed"
'

# ------------------------------------------------------------------
# Report
# ------------------------------------------------------------------
reportResults
