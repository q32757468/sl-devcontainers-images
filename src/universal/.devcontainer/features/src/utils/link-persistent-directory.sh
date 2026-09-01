#!/usr/bin/env bash
set -euo pipefail

storage_type="${1:?Usage: link-persistent-directory.sh <config|cache> <home-relative-path>}"
relative_path="${2:?Usage: link-persistent-directory.sh <config|cache> <home-relative-path>}"

case "${relative_path}" in
    . | ./ | /* | ../* | */../* | */..)
        echo "Persistent path must be relative to HOME and must not contain '..': ${relative_path}." >&2
        exit 1
        ;;
esac

source /usr/local/share/devcontainer-features/utils/utils.sh
link_persistent_directory "${storage_type}" "${HOME}/${relative_path#./}"
