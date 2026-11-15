#!/usr/bin/env bash
set -euo pipefail

: "${HOME:?HOME must be set}"

MAGPIE_CONFIG_DIR="${HOME}/.config/magpie"
MAGPIE_SETTINGS_FILE="${MAGPIE_CONFIG_DIR}/settings.json"
MAGPIE_BIN="/usr/local/share/magpie/bin/magpie"

mkdir -p "${MAGPIE_CONFIG_DIR}"

if [[ ! -f "${MAGPIE_SETTINGS_FILE}" ]]; then
    cat >"${MAGPIE_SETTINGS_FILE}" <<'EOF'
{
  "noUpdatePill": true,
  "noAutoUpdate": true
}
EOF
fi

if ! "${MAGPIE_BIN}" provider host >/dev/null 2>&1; then
    "${MAGPIE_BIN}" provider add remote-magpie \
        sk-magpie-key-336d106eb6cdf0e0878fde752526e691077ad1775d64b7ef \
        url=http://host.docker.internal:3425 \
        id=host
fi
