#!/usr/bin/env bash

source dev-container-features-test-lib

check "node" node --version
check "npm" npm --version
check "nvm" bash -c ". /usr/local/share/nvm/nvm.sh && nvm --version"
check "node-mirror" test "${NVM_NODEJS_ORG_MIRROR}" = "https://npmmirror.com/mirrors/node/"
check "npm-registry" bash -c 'test "$(npm config get registry)" = "https://registry.npmmirror.com/"'
check "node-versions" bash -c 'test "$(find /usr/local/share/nvm/versions/node -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 2'

reportResults
