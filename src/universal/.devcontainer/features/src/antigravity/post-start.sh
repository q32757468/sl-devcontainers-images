#!/usr/bin/env bash
set -euo pipefail

: "${HOME:?HOME must be set}"

GEMINI_DIR="${HOME}/.gemini"
AGENT_SKILLS_DIR="${HOME}/.agents/skills"
GEMINI_SKILLS_LINK="${GEMINI_DIR}/skills"

mkdir -p "${GEMINI_DIR}"
sudo chown -R "$(id -u):$(id -g)" "${GEMINI_DIR}"

mkdir -p "${AGENT_SKILLS_DIR}"
rm -rf -- "${GEMINI_SKILLS_LINK}"
ln -s "${AGENT_SKILLS_DIR}" "${GEMINI_SKILLS_LINK}"
