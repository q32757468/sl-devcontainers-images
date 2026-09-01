#!/usr/bin/env bash
set -euo pipefail

: "${HOME:?HOME must be set}"

CODEX_DIR="${HOME}/.codex"
CODEX_CONFIG="${CODEX_DIR}/config.toml"
ATTENTIVE_MARKETPLACE_DIR="/usr/local/share/codex/marketplaces/attentive"
ATTENTIVE_MARKETPLACE_NAME="attentive-codex-plugins"

set_top_level_config_value() {
    local key="${1:?Usage: set_top_level_config_value <key> <TOML value>}"
    local value="${2:?Usage: set_top_level_config_value <key> <TOML value>}"
    local temporary_config

    sed -i "/^[[:space:]]*${key}[[:space:]]*=/d" "${CODEX_CONFIG}"
    temporary_config="$(mktemp "${CODEX_CONFIG}.tmp.XXXXXX")"
    {
        printf '%s = %s\n' "${key}" "${value}"
        cat "${CODEX_CONFIG}"
    } > "${temporary_config}"
    mv -- "${temporary_config}" "${CODEX_CONFIG}"
}

mkdir -p "${CODEX_DIR}"
touch "${CODEX_CONFIG}"
set_top_level_config_value "sandbox_mode" '"danger-full-access"'
set_top_level_config_value "approval_policy" '"never"'

echo "(*) Installing the attentive-codex-notify plugin..."
# Codex does not allow a marketplace name to be registered from a new source.
# The config is persistent, so remove a registration left by an older source
# before adding the bundled local marketplace.  On a first install there is
# nothing to remove, hence the intentionally ignored exit status.
codex plugin marketplace remove "${ATTENTIVE_MARKETPLACE_NAME}" >/dev/null 2>&1 || true
codex plugin marketplace add "${ATTENTIVE_MARKETPLACE_DIR}"
codex plugin add "attentive-codex-notify@${ATTENTIVE_MARKETPLACE_NAME}"
