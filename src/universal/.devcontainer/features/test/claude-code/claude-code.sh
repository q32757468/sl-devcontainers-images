#!/usr/bin/env bash

source dev-container-features-test-lib

check "claude" claude --version
check "claude-config" bash -c '
    test -f "${HOME}/.claude.json"
    test "$(jq -r ".autoUpdates" "${HOME}/.claude.json")" = "false"
'
check "claude-settings" bash -c '
    test "$(jq -r ".permissions.defaultMode" "${HOME}/.claude/settings.json")" = "bypassPermissions"
    test "$(jq -r ".skipDangerousModePermissionPrompt" "${HOME}/.claude/settings.json")" = "true"
'
check "claude-skills-link" bash -c '
    test -L "${HOME}/.claude/skills"
    test "$(readlink "${HOME}/.claude/skills")" = "${HOME}/.agents/skills"
'
check "claude-post-create" test -x /usr/local/share/devcontainer-features/claude-code/post-create.sh
check "claude-post-start" test -x /usr/local/share/devcontainer-features/claude-code/post-start.sh

reportResults
