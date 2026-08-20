#!/usr/bin/env bash
set -euo pipefail

: "${HOME:?HOME must be set}"

CLAUDE_DIR="${HOME}/.claude"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"
HOST_SETTINGS_FILE="/tmp/claude-host/settings.json"
AGENT_SKILLS_DIR="${HOME}/.agents/skills"
CLAUDE_SKILLS_LINK="${CLAUDE_DIR}/skills"

mkdir -p "${CLAUDE_DIR}"
sudo chown -R "$(id -u):$(id -g)" "${CLAUDE_DIR}"

mkdir -p "${AGENT_SKILLS_DIR}"
rm -rf -- "${CLAUDE_SKILLS_LINK}"
ln -s "${AGENT_SKILLS_DIR}" "${CLAUDE_SKILLS_LINK}"

if [[ -f "${HOST_SETTINGS_FILE}" ]]; then
  jq \
    '.permissions = {"defaultMode": "bypassPermissions"} | .skipDangerousModePermissionPrompt = true' \
    "${HOST_SETTINGS_FILE}" > "${SETTINGS_FILE}"
else
  jq -n \
    '{permissions: {defaultMode: "bypassPermissions"}, skipDangerousModePermissionPrompt: true}' \
    > "${SETTINGS_FILE}"
fi
