#!/usr/bin/env bash

source dev-container-features-test-lib

check "rustc" rustc --version
check "cargo" cargo --version
check "rustup" rustup --version
check "rustfmt" rustfmt --version
check "clippy" cargo clippy --version
check "rust-src" bash -c "rustup component list --installed | grep -q '^rust-src'"
check "excluded-components" bash -c "! rustup component list --installed | grep -Eq '^(rust-docs|llvm-tools|rust-analysis)-'"
check "stable-toolchain" bash -c "rustup show active-toolchain | grep -q '^stable-'"
check "cargo-home" bash -c 'test -z "${CARGO_HOME:-}" && test -d "${HOME}/.cargo"'
check "cargo-config" bash -c '
    config="${HOME}/.cargo/config.toml"
    test -f "${config}"
    grep -Fxq "[source.crates-io]" "${config}"
    grep -Fxq "replace-with = '\''rsproxy-sparse'\''" "${config}"
    grep -Fxq "registry = \"sparse+https://rsproxy.cn/index/\"" "${config}"
    grep -Fxq "git-fetch-with-cli = true" "${config}"
'

reportResults
