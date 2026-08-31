#!/usr/bin/env bash

source dev-container-features-test-lib

APT_SOURCES_FILE="/etc/apt/sources.list.d/ubuntu.sources"

check "apt-sources-file" test -f "${APT_SOURCES_FILE}"
check "tuna-http-mirror" bash -c '
    set -e
    grep -Fq "URIs: http://mirrors.tuna.tsinghua.edu.cn/ubuntu/" "/etc/apt/sources.list.d/ubuntu.sources"
    ! grep -Fq "archive.ubuntu.com" "/etc/apt/sources.list.d/ubuntu.sources"
    ! grep -Fq "security.ubuntu.com" "/etc/apt/sources.list.d/ubuntu.sources"
    ! grep -Fq "https://mirrors.tuna.tsinghua.edu.cn/ubuntu/" "/etc/apt/sources.list.d/ubuntu.sources"
'

reportResults
