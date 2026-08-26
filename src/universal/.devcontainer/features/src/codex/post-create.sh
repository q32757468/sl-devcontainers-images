#!/usr/bin/env bash
set -euo pipefail

ATTENTIVE_MARKETPLACE_DIR="/usr/local/share/codex/marketplaces/attentive"
ATTENTIVE_MARKETPLACE_NAME="attentive-codex-plugins"

echo "(*) Installing the attentive-codex-notify plugin..."
# Codex does not allow a marketplace name to be registered from a new source.
# The config is persistent, so remove a registration left by an older source
# before adding the bundled local marketplace.  On a first install there is
# nothing to remove, hence the intentionally ignored exit status.
codex plugin marketplace remove "${ATTENTIVE_MARKETPLACE_NAME}" >/dev/null 2>&1 || true
codex plugin marketplace add "${ATTENTIVE_MARKETPLACE_DIR}"
codex plugin add "attentive-codex-notify@${ATTENTIVE_MARKETPLACE_NAME}"
