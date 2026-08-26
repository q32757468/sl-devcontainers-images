#!/usr/bin/env bash
set -euo pipefail

ATTENTIVE_MARKETPLACE_DIR="/usr/local/share/codex/marketplaces/attentive"

echo "(*) Installing the attentive-codex-notify plugin..."
codex plugin marketplace add "${ATTENTIVE_MARKETPLACE_DIR}"
codex plugin add attentive-codex-notify@attentive-codex-plugins
