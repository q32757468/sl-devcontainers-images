#!/usr/bin/env bash
set -e

echo "(*) Configuring APT source mirror..."

SOURCES_FILE="/etc/apt/sources.list.d/ubuntu.sources"
TUNA_MIRROR="http://mirrors.tuna.tsinghua.edu.cn/ubuntu/"

if [[ ! -f "${SOURCES_FILE}" ]]; then
    echo "Ubuntu APT sources file not found: ${SOURCES_FILE}." >&2
    exit 1
fi

sed -E -i \
    -e "s|https?://archive\\.ubuntu\\.com/ubuntu/?|${TUNA_MIRROR}|g" \
    -e "s|https?://security\\.ubuntu\\.com/ubuntu/?|${TUNA_MIRROR}|g" \
    -e "s|https://mirrors\\.tuna\\.tsinghua\\.edu\\.cn/ubuntu/?|${TUNA_MIRROR}|g" \
    "${SOURCES_FILE}"

echo "APT sources configured to use ${TUNA_MIRROR}."
echo "Done!"
