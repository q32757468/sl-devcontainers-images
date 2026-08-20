#!/usr/bin/env bash

source dev-container-features-test-lib

check "codex" codex --version
check "codex-config" bash -c '
    config="${HOME}/.codex/config.toml"
    test -f "${config}"
    grep -Fxq "approval_policy = \"never\"" "${config}"
    grep -Fxq "sandbox_mode = \"danger-full-access\"" "${config}"
'
check "codex-post-start" test -x /usr/local/share/devcontainer-features/codex/post-start.sh

reportResults
