#!/usr/bin/env bash

source dev-container-features-test-lib

check "magpie" magpie --version
check "magpie-path" bash -c '
    test "$(command -v magpie)" = "/usr/local/share/magpie/bin/magpie"
'
check "magpie-config-link" bash -c '
    test -L "${HOME}/.config/magpie"
    test "$(readlink "${HOME}/.config/magpie")" = "${HOME}/.sl-config/.config/magpie"
'
check "magpie-settings" bash -c '
    settings="${HOME}/.config/magpie/settings.json"
    test -f "${settings}"
    test "$(jq -r ".noUpdatePill" "${settings}")" = "true"
    test "$(jq -r ".noAutoUpdate" "${settings}")" = "true"
'
check "magpie-settings-preserved" bash -c '
    settings="${HOME}/.config/magpie/settings.json"
    temporary="$(mktemp)"
    jq ".theme = \"dark\"" "${settings}" >"${temporary}"
    mv -- "${temporary}" "${settings}"

    /usr/local/share/devcontainer-features/magpie/post-create.sh

    test "$(jq -r ".theme" "${settings}")" = "dark"
    test "$(jq -r ".noUpdatePill" "${settings}")" = "true"
    test "$(jq -r ".noAutoUpdate" "${settings}")" = "true"
'
check "magpie-remote-provider" bash -c '
    providers="${HOME}/.config/magpie/providers.json"
    test -f "${providers}"
    test "$(jq -r '\''.providers[] | select(.id == "host") | .preset'\'' "${providers}")" = "remote-magpie"
    test "$(jq -r '\''.providers[] | select(.id == "host") | .key'\'' "${providers}")" = "sk-magpie-key-336d106eb6cdf0e0878fde752526e691077ad1775d64b7ef"
    test "$(jq -r '\''.providers[] | select(.id == "host") | .chat'\'' "${providers}")" = "http://host.docker.internal:3425/v1"
    test "$(jq -r '\''.providers[] | select(.id == "host") | .anthropic'\'' "${providers}")" = "http://host.docker.internal:3425"
'
check "magpie-post-create-idempotency" bash -c '
    providers="${HOME}/.config/magpie/providers.json"

    /usr/local/share/devcontainer-features/magpie/post-create.sh

    test "$(jq '\''[.providers[] | select(.id == "host")] | length'\'' "${providers}")" -eq 1
'
check "magpie-address" bash -c 'test "${MAGPIE_ADDR}" = "127.0.0.1:3426"'
check "magpie-post-create" test -x /usr/local/share/devcontainer-features/magpie/post-create.sh
check "magpie-serve" bash -c '
    for _ in $(seq 1 50); do
        if magpie healthcheck; then
            exit 0
        fi
        sleep 0.1
    done
    cat /tmp/magpie-serve.log >&2
    exit 1
'
check "magpie-post-start" test -x /usr/local/share/devcontainer-features/magpie/post-start.sh

reportResults
