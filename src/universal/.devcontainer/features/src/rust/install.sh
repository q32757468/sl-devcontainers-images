#!/usr/bin/env bash
set -e

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Installing Rust..."

REMOTE_USER_HOME="$(get_remote_user_home)"
REMOTE_CARGO_HOME="${REMOTE_USER_HOME}/.cargo"
RUST_BIN_DIR="/usr/local/share/rust/bin"

run_as_remote_user sh -c "curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh -s -- -y --no-modify-path --default-toolchain stable --profile minimal --component rust-analyzer,rust-src,rustfmt,clippy"

# Keep the user's Cargo bin directory available to every container process without
# changing CARGO_HOME from Cargo's default of ${REMOTE_USER_HOME}/.cargo.
install -d -m 0755 "$(dirname "${RUST_BIN_DIR}")"
ln -sfn "${REMOTE_CARGO_HOME}/bin" "${RUST_BIN_DIR}"

run_as_remote_user mkdir -p "${REMOTE_CARGO_HOME}/registry"

echo "(*) Configuring Cargo registry mirrors..."

CARGO_CONFIG_CONTENT="$(cat << 'EOF'
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
  )"

printf '%s\n' "${CARGO_CONFIG_CONTENT}" \
    | run_as_remote_user tee "${REMOTE_CARGO_HOME}/config.toml" > /dev/null

echo "Done!"
