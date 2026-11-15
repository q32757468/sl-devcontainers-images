#!/usr/bin/env bash
set -euo pipefail

MAGPIE_BIN="/usr/local/share/magpie/bin/magpie"

if ! pgrep -f -- "${MAGPIE_BIN} serve" >/dev/null 2>&1; then
    setsid --fork "${MAGPIE_BIN}" serve </dev/null >/tmp/magpie-serve.log 2>&1
fi
