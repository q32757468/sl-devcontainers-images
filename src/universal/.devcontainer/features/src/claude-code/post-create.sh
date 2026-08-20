#!/usr/bin/env bash
set -euo pipefail

: "${HOME:?HOME must be set}"

# Seed ~/.claude.json so Claude Code registers the workspace as a known project.
# postCreateCommand runs with cwd set to the workspace folder, so pwd is the workspace dir.
CLAUDE_JSON_FILE="${HOME}/.claude.json"
WORKSPACE_DIR="$(pwd)"

mkdir -p "$(dirname "${CLAUDE_JSON_FILE}")"

if [[ -f "${CLAUDE_JSON_FILE}" ]]; then
  # Merge in memory: keep existing state, only ensure the workspace entry exists.
  UPDATED_JSON="$(jq --arg ws "${WORKSPACE_DIR}" \
    '(.projects[$ws] //= {}) | .projects[$ws].hasTrustDialogAccepted = true' \
    "${CLAUDE_JSON_FILE}")"
  printf '%s\n' "${UPDATED_JSON}" > "${CLAUDE_JSON_FILE}"
else
  jq -n --arg ws "${WORKSPACE_DIR}" \
    '{projects: {($ws): {hasTrustDialogAccepted: true}}}' > "${CLAUDE_JSON_FILE}"
fi
