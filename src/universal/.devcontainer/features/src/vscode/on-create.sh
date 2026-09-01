#!/usr/bin/env bash
set -euo pipefail

: "${HOME:?HOME must be set}"

VSCODE_EXTENSIONS_DIR="${HOME}/.vscode-server/extensions"

if [[ -L "${VSCODE_EXTENSIONS_DIR}" ]]; then
    VSCODE_EXTENSIONS_TARGET="$(readlink "${VSCODE_EXTENSIONS_DIR}")"
    case "${VSCODE_EXTENSIONS_TARGET}" in
        /*) ;;
        *) VSCODE_EXTENSIONS_TARGET="$(dirname "${VSCODE_EXTENSIONS_DIR}")/${VSCODE_EXTENSIONS_TARGET}" ;;
    esac
    mkdir -p -- "${VSCODE_EXTENSIONS_TARGET}"
else
    mkdir -p -- "${VSCODE_EXTENSIONS_DIR}"
fi
