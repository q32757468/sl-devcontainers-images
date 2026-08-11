#!/bin/bash
cd $(dirname "$0")

source test-utils.sh

# ------------------------------------------------------------------
# Basic system checks
# ------------------------------------------------------------------
check "non-root-user" id hsl
check "locale" [ $(locale -a | grep C.utf8) ]
check "timezone" [ "$(readlink -f /etc/localtime)" = "/usr/share/zoneinfo/Asia/Shanghai" ]
check "sudo" sudo echo "sudo works."
check "bash" bash --version

# System packages
checkOSPackages "system-packages" vim curl ca-certificates git sudo

# ------------------------------------------------------------------
# Node.js
# ------------------------------------------------------------------
check "node" node --version
check "npm" npm --version
check "nvm" bash -c ". /usr/local/share/nvm/nvm.sh && nvm --version"
check "pnpm" pnpm --version
check "codex" codex --version
check "agent-browser" agent-browser --version
check "agent-browser-offline-page" bash -c '
    set -e
    trap "agent-browser close >/dev/null 2>&1 || true" EXIT
    agent-browser open "data:text/html,<title>Agent Browser Test</title><h1>Offline</h1>"
    agent-browser get title | grep -Fx "Agent Browser Test"
'
check "configure-devcontainer-skill" bash -c '
    set -e
    skill_path="$HOME/.agents/skills/configure-devcontainer/SKILL.md"
    test -f "$skill_path"
    grep -Fq "  codex-config:" "$skill_path"
    grep -Fq "  claude-code-config:" "$skill_path"
    test "$(grep -Fc "    external: true" "$skill_path")" -ge 2
'

# Verify two Node versions installed
count=$(ls /usr/local/share/nvm/versions/node | wc -l)
checkVersionCount "two versions of node are present" $count 2
echo $(echo "node versions:" && ls -a /usr/local/share/nvm/versions/node)

# Default Node version check
check "default-node-version" bash -c "node --version | grep 24."

# ------------------------------------------------------------------
# Python
# ------------------------------------------------------------------
check "python3" python3 --version
check "pip3" pip3 --version
check "uv" uv --version

# Verify system Python is 3.12
check "python-3.12" bash -c "python3 --version | grep '3\.12'"

# Test uv can create a venv and install a package
check "uv-venv" bash -c "cd /tmp && uv venv --python python3 /tmp/test-uv-venv && rm -rf /tmp/test-uv-venv"

# ------------------------------------------------------------------
# Rust
# ------------------------------------------------------------------
check "rustc" rustc --version
check "cargo" cargo --version
check "rustup" rustup --version
check "rustfmt" rustfmt --version
check "clippy" cargo clippy --version
check "rust-src" bash -c "rustup component list --installed | grep rust-src"
check "rust-analyzer" rust-analyzer --version
check "excluded-rust-components" bash -c "! rustup component list --installed | grep -E '^(rust-docs|llvm-tools|rust-analysis)-'"
check "cargo-config" bash -c '
    set -e
    config="${CARGO_HOME:?CARGO_HOME must be set}/config.toml"
    test -f "$config"
    grep -Fxq "[source.crates-io]" "$config"
    grep -Fxq "replace-with = '\''rsproxy-sparse'\''" "$config"
    grep -Fxq "registry = \"https://rsproxy.cn/crates.io-index\"" "$config"
    grep -Fxq "registry = \"sparse+https://rsproxy.cn/index/\"" "$config"
    grep -Fxq "index = \"https://rsproxy.cn/crates.io-index\"" "$config"
    grep -Fxq "git-fetch-with-cli = true" "$config"
'

# Verify Rust is stable channel
check "rust-stable" bash -c "rustup show active-toolchain | grep stable"

# ------------------------------------------------------------------
# Report
# ------------------------------------------------------------------
reportResults
