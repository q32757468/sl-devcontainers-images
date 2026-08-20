#!/usr/bin/env bash

source dev-container-features-test-lib

check "agent-browser" agent-browser --version
check "puppeteer" puppeteer --version
check "puppeteer-chrome-for-testing" bash -c '
    chrome_path="$(find "${HOME}/.cache/puppeteer/chrome" -type f -path "*/chrome-linux*/chrome" -perm /111 -print -quit)"
    test -n "${chrome_path}"
    "${chrome_path}" --version | grep -F "Chrome for Testing"
'
check "agent-browser-offline-page" bash -c '
    set -e
    trap "agent-browser close >/dev/null 2>&1 || true" EXIT
    agent-browser open "data:text/html,<title>Agent Browser Test</title><h1>Offline</h1>"
    agent-browser get title | grep -Fx "Agent Browser Test"
'
check "agent-browser-skill" test -d "${HOME}/.agents/skills/agent-browser"

reportResults
