#!/usr/bin/env bash

source dev-container-features-test-lib

check "runtime-user" bash -c 'test "$(id -un)" = "ubuntu"'
check "agy" agy --version
check "agy-install-dir" test -x /usr/local/share/antigravity/bin/agy
check "agy-path" bash -c 'test "$(command -v agy)" = "/usr/local/share/antigravity/bin/agy"'
check "gemini-config-dir" test -d "${HOME}/.gemini"
check "gemini-config-owner" bash -c '
    expected="$(id -u):$(id -g)"
    test "$(stat -c "%u:%g" "${HOME}/.gemini")" = "${expected}"
'
check "gemini-skills-link" bash -c '
    test -L "${HOME}/.gemini/skills"
    test "$(readlink "${HOME}/.gemini/skills")" = "${HOME}/.agents/skills"
'
check "antigravity-post-start" test -x /usr/local/share/devcontainer-features/antigravity/post-start.sh

reportResults
