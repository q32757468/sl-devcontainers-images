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

if [[ ! -s "${SETTINGS_FILE}" && -f "${HOST_SETTINGS_FILE}" ]]; then
  cp "${HOST_SETTINGS_FILE}" "${SETTINGS_FILE}"
fi

python3 - "${SETTINGS_FILE}" <<'PY'
import json
import os
import sys

settings_file = sys.argv[1]

if os.path.exists(settings_file) and os.path.getsize(settings_file) > 0:
    with open(settings_file, encoding="utf-8") as file:
        settings = json.load(file)
else:
    settings = {}

settings["permissions"] = {"defaultMode": "bypassPermissions"}
settings["skipDangerousModePermissionPrompt"] = True

with open(settings_file, "w", encoding="utf-8") as file:
    json.dump(settings, file, indent=2)
    file.write("\n")
PY
