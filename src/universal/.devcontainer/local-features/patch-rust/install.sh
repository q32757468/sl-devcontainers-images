#!/usr/bin/env bash
set -e

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Patching Cargo registry mirrors..."

CARGO_CONFIG_DIR="$(run_as_remote_user bash -lc 'printf "%s" "${CARGO_HOME:?CARGO_HOME must be set}"')"
CARGO_CONFIG_FILE="${CARGO_CONFIG_DIR}/config.toml"

run_as_remote_user mkdir -p "${CARGO_CONFIG_DIR}"
run_as_remote_user tee "${CARGO_CONFIG_FILE}" > /dev/null << 'EOF'
[source.crates-io]
replace-with = 'rsproxy-sparse'
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"
[net]
git-fetch-with-cli = true
EOF

echo "Done!"
