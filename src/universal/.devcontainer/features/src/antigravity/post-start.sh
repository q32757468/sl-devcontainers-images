#!/usr/bin/env bash
set -euo pipefail

: "${HOME:?HOME must be set}"

GEMINI_DIR="${HOME}/.gemini"
SETTINGS_DIR="${GEMINI_DIR}/antigravity-cli"
SETTINGS_FILE="${SETTINGS_DIR}/settings.json"
AGENT_SKILLS_DIR="${HOME}/.agents/skills"
GEMINI_SKILLS_LINK="${GEMINI_DIR}/skills"
SETTINGS_TEMP_FILE=""

cleanup() {
    if [[ -n "${SETTINGS_TEMP_FILE}" ]]; then
        rm -f -- "${SETTINGS_TEMP_FILE}"
    fi
}
trap cleanup EXIT

mkdir -p "${GEMINI_DIR}"

mkdir -p "${AGENT_SKILLS_DIR}"
rm -rf -- "${GEMINI_SKILLS_LINK}"
ln -s "${AGENT_SKILLS_DIR}" "${GEMINI_SKILLS_LINK}"

mkdir -p "${SETTINGS_DIR}"
SETTINGS_TEMP_FILE="$(mktemp "${SETTINGS_FILE}.tmp.XXXXXX")"

if [[ -f "${SETTINGS_FILE}" ]]; then
    jq '
        .agentMode = "accept-edits"
        | .toolPermission = "always-proceed"
        | .artifactReviewPolicy = "always-proceed"
    ' "${SETTINGS_FILE}" > "${SETTINGS_TEMP_FILE}"
else
    jq -n '{
        agentMode: "accept-edits",
        toolPermission: "always-proceed",
        artifactReviewPolicy: "always-proceed"
    }' > "${SETTINGS_TEMP_FILE}"
fi

mv -- "${SETTINGS_TEMP_FILE}" "${SETTINGS_FILE}"
SETTINGS_TEMP_FILE=""
