#!/usr/bin/env bash

source dev-container-features-test-lib

check "codex" codex --version
check "codex-config-link" bash -c '
    test -L "${HOME}/.codex"
    test "$(readlink "${HOME}/.codex")" = "${HOME}/.sl-config/.codex"
'
check "codex-config" bash -c '
    config="${HOME}/.codex/config.toml"
    test -f "${config}"
    grep -Fxq "approval_policy = \"never\"" "${config}"
    grep -Fxq "sandbox_mode = \"danger-full-access\"" "${config}"
'
check "codex-post-start" test -x /usr/local/share/devcontainer-features/codex/post-start.sh
check "codex-post-create" test -x /usr/local/share/devcontainer-features/codex/post-create.sh
check "attentive-marketplace-source" bash -c '
    marketplace="/usr/local/share/codex/marketplaces/attentive/.agents/plugins/marketplace.json"
    test -f "${marketplace}"
    grep -Fq "\"name\": \"attentive-codex-plugins\"" "${marketplace}"
'
check "attentive-plugin-config" bash -c '
    config="${HOME}/.codex/config.toml"
    grep -Fq "[marketplaces.attentive-codex-plugins]" "${config}"
    grep -Fq "source = \"/usr/local/share/codex/marketplaces/attentive\"" "${config}"
    grep -Fq "[plugins.\"attentive-codex-notify@attentive-codex-plugins\"]" "${config}"
    grep -Fq "enabled = true" "${config}"
'
check "attentive-plugin-cache" bash -c '
    cache_root="${HOME}/.codex/plugins/cache/attentive-codex-plugins/attentive-codex-notify"
    manifest="$(find "${cache_root}" -mindepth 3 -maxdepth 3 -name plugin.json -path "*/.codex-plugin/plugin.json" -print -quit)"
    test -n "${manifest}"
    grep -Fq "\"name\": \"attentive-codex-notify\"" "${manifest}"
'

reportResults
