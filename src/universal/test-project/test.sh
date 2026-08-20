#!/bin/bash
cd "$(dirname "$0")"

source test-utils.sh

# ------------------------------------------------------------------
# Basic system checks
# ------------------------------------------------------------------
check "non-root-user" id hsl
check "locale" bash -c "locale -a | grep -q C.utf8"
check "timezone" test "$(readlink -f /etc/localtime)" = "/usr/share/zoneinfo/Asia/Shanghai"
check "sudo" sudo echo "sudo works."
check "bash" bash --version

# System packages
checkOSPackages "system-packages" vim curl ca-certificates git sudo

# ------------------------------------------------------------------
# Feature smoke checks
# ------------------------------------------------------------------
check "node" node --version
check "npm" npm --version
check "nvm" bash -c ". /usr/local/share/nvm/nvm.sh && nvm --version"
check "pnpm" pnpm --version
check "codex" codex --version
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

# ------------------------------------------------------------------
# Report
# ------------------------------------------------------------------
reportResults
