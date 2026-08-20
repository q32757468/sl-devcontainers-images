#!/usr/bin/env bash

source dev-container-features-test-lib

check "pnpm" pnpm --version
check "pnpm-home" test "${PNPM_HOME}" = "/usr/local/share/pnpm"
check "pnpm-registry" bash -c 'test "$(pnpm config get registry)" = "https://registry.npmmirror.com/"'
check "pnpm-user" bash -c 'test -w "${PNPM_HOME}"'

reportResults
