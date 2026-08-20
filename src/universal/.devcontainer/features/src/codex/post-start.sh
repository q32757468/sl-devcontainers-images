#!/usr/bin/env bash
set -euo pipefail

: "${HOME:?HOME must be set}"

CODEX_DIR="${HOME}/.codex"
AUTH_FILE="${CODEX_DIR}/auth.json"
HOST_AUTH_FILE="/tmp/codex-host/auth.json"

mkdir -p "${CODEX_DIR}"
sudo chown -R "$(id -u):$(id -g)" "${CODEX_DIR}"

if [[ -f "${HOST_AUTH_FILE}" ]]; then
    cp "${HOST_AUTH_FILE}" "${AUTH_FILE}"
fi
