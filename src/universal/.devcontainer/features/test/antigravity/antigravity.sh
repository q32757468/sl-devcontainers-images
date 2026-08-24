#!/usr/bin/env bash

source dev-container-features-test-lib

check "runtime-user" bash -c 'test "$(id -un)" = "ubuntu"'
check "agy" agy --version
check "agy-install-dir" test -x /usr/local/share/antigravity/bin/agy
check "agy-path" bash -c 'test "$(command -v agy)" = "/usr/local/share/antigravity/bin/agy"'
check "gemini-config-link" bash -c '
    test -L "${HOME}/.gemini"
    test "$(readlink "${HOME}/.gemini")" = "${HOME}/.sl-config/.gemini"
'
check "gemini-config-dir" test -d "${HOME}/.gemini"
check "gemini-config-owner" bash -c '
    expected="$(id -u):$(id -g)"
    test "$(stat -c "%u:%g" "${HOME}/.gemini")" = "${expected}"
'
check "gemini-skills-link" bash -c '
    test -L "${HOME}/.gemini/skills"
    test "$(readlink "${HOME}/.gemini/skills")" = "${HOME}/.agents/skills"
'
check "antigravity-yolo-settings" bash -c '
    settings="${HOME}/.gemini/antigravity-cli/settings.json"
    test -f "${settings}"
    test "$(jq -r ".agentMode" "${settings}")" = "accept-edits"
    test "$(jq -r ".toolPermission" "${settings}")" = "always-proceed"
    test "$(jq -r ".artifactReviewPolicy" "${settings}")" = "always-proceed"
'
check "antigravity-settings-idempotent-merge" bash -c '
    settings="${HOME}/.gemini/antigravity-cli/settings.json"
    temp_file="$(mktemp)"
    jq ".showTips = false" "${settings}" > "${temp_file}"
    mv "${temp_file}" "${settings}"

    /usr/local/share/devcontainer-features/antigravity/post-start.sh

    test "$(jq -r ".showTips" "${settings}")" = "false"
    test "$(jq -r ".agentMode" "${settings}")" = "accept-edits"
    test "$(jq -r ".toolPermission" "${settings}")" = "always-proceed"
    test "$(jq -r ".artifactReviewPolicy" "${settings}")" = "always-proceed"
'
check "antigravity-post-start" test -x /usr/local/share/devcontainer-features/antigravity/post-start.sh

reportResults
