#!/usr/bin/env bash
set -euo pipefail

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Installing Codex..."

install_lifecycle_script codex
install_lifecycle_script codex post-create
GITHUB_MIRROR="${GITHUBMIRROR}"
ATTENTIVE_SOURCE_URL="https://github.com/q32757468/attentive/archive/refs/heads/main.tar.gz"
ATTENTIVE_MARKETPLACE_DIR="/usr/local/share/codex/marketplaces/attentive"

prepare_attentive_codex_notify() (
    local temp_dir
    local archive_path
    local source_dir
    local download_url
    local extracted_source_dir

    temp_dir="$(mktemp -d)"
    archive_path="${temp_dir}/attentive-main.tar.gz"
    source_dir="${temp_dir}/source"
    trap 'rm -rf -- "${temp_dir}"' EXIT

    download_url="${ATTENTIVE_SOURCE_URL}"
    if [[ -n "${GITHUB_MIRROR}" ]]; then
        download_url="${GITHUB_MIRROR%/}/${ATTENTIVE_SOURCE_URL}"
    fi

    echo "(*) Downloading the Attentive source archive..."
    curl --fail --location --silent --show-error --retry 3 \
        --connect-timeout 10 --output "${archive_path}" "${download_url}"
    mkdir -p "${source_dir}"
    tar -xzf "${archive_path}" -C "${source_dir}"

    extracted_source_dir="${source_dir}/attentive-main"
    install -d -m 0755 "$(dirname "${ATTENTIVE_MARKETPLACE_DIR}")"
    rm -rf -- "${ATTENTIVE_MARKETPLACE_DIR}"
    mv "${extracted_source_dir}" "${ATTENTIVE_MARKETPLACE_DIR}"
)

# Install the Codex CLI as the remote user so its global pnpm package remains writable.
run_as_remote_user \
    pnpm add --config.minimum-release-age=0 -g @openai/codex

# Prepare the attentive-codex-notify source marketplace for post-create installation.
prepare_attentive_codex_notify

echo "Done!"
