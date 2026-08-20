#!/usr/bin/env bash

source dev-container-features-test-lib

check "agent-browser" agent-browser --version
check "agent-browser-offline-page" bash -c '
    set -e
    trap "agent-browser close >/dev/null 2>&1 || true" EXIT
    agent-browser open "data:text/html,<title>Agent Browser Test</title><h1>Offline</h1>"
    agent-browser get title | grep -Fx "Agent Browser Test"
'
check "agent-browser-skill" test -d "${HOME}/.agents/skills/agent-browser"

reportResults
