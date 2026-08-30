#!/usr/bin/env bash

source dev-container-features-test-lib

check "runtime-user" bash -c 'test "$(id -un)" = "ubuntu"'
check "herdr" herdr --version
check "herdr-install-dir" test -x /usr/local/share/herdr/bin/herdr
check "herdr-install-owner" bash -c 'test "$(stat -c %U /usr/local/share/herdr/bin/herdr)" = "$(id -un)"'
check "herdr-path" bash -c 'test "$(command -v herdr)" = "/usr/local/share/herdr/bin/herdr"'

reportResults
