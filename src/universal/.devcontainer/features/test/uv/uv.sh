#!/usr/bin/env bash

source dev-container-features-test-lib

check "uv" uv --version
check "uv-install-dir" test -x /usr/local/share/uv/uv
check "uv-default-index" test "${UV_DEFAULT_INDEX}" = "https://mirrors.aliyun.com/pypi/simple/"
check "uv-venv" env UV_PYTHON_DOWNLOADS=never bash -c '
    test_dir="$(mktemp -d)"
    trap '\''rm -rf -- "${test_dir}"'\'' EXIT
    uv venv --python python3 "${test_dir}/venv"
'

reportResults
