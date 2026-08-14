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

# Seed ~/.claude.json so Claude Code registers the workspace as a known project.
# postStartCommand runs with cwd set to the workspace folder, so pwd is the workspace dir.
CLAUDE_JSON_FILE="${HOME}/.claude.json"
WORKSPACE_DIR="$(pwd)"

if [[ -f "${CLAUDE_JSON_FILE}" ]]; then
  # Merge in memory: keep existing state, only ensure the workspace entry exists.
  UPDATED_JSON="$(jq --arg ws "${WORKSPACE_DIR}" \
    '(.projects[$ws] //= {})' \
    "${CLAUDE_JSON_FILE}")"
  printf '%s\n' "${UPDATED_JSON}" > "${CLAUDE_JSON_FILE}"
else
  jq -n --arg ws "${WORKSPACE_DIR}" \
    '{projects: {($ws): {}}}' > "${CLAUDE_JSON_FILE}"
fi
