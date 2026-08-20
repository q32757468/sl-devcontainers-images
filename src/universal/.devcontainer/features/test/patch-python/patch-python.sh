#!/usr/bin/env bash

source dev-container-features-test-lib

check "pip-config" bash -c '
    config="${HOME}/.config/pip/pip.conf"
    test -f "${config}"
    grep -Fxq "index-url = https://mirrors.aliyun.com/pypi/simple/" "${config}"
    grep -Fxq "trusted-host = mirrors.aliyun.com" "${config}"
'

reportResults
