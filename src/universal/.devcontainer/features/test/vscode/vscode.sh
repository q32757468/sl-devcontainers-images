#!/usr/bin/env bash

source dev-container-features-test-lib

check "vscode-server-extensions-link" bash -c '
    test -L "${HOME}/.vscode-server/extensions"
    test "$(readlink "${HOME}/.vscode-server/extensions")" = "${HOME}/.sl-cache/.vscode-server/extensions"
'
check "vscode-server-extensions-dir" test -d "${HOME}/.vscode-server/extensions"
check "vscode-server-extensions-cache-dir" test -d "${HOME}/.sl-cache/.vscode-server/extensions"
check "vscode-server-extensions-owner" bash -c '
    expected="$(id -u):$(id -g)"
    test "$(stat -c "%u:%g" "${HOME}/.vscode-server/extensions")" = "${expected}"
'

reportResults
