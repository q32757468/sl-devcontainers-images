#!/usr/bin/env bash
set -euo pipefail

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Installing Antigravity CLI..."

install_lifecycle_script antigravity

INSTALL_DIR="/usr/local/share/antigravity"
BIN_DIR="${INSTALL_DIR}/bin"
GITHUB_API_URL="https://api.github.com/repos/google-antigravity/antigravity-cli/releases/latest"
REMOTE_USER_HOME="$(get_remote_user_home)"
SYSTEM_ARCH="$(uname -m)"

case "${SYSTEM_ARCH}" in
    x86_64 | amd64)
        RELEASE_ARCH="x64"
        ;;
    aarch64 | arm64)
        RELEASE_ARCH="arm64"
        ;;
    *)
        echo "Fatal: Unsupported architecture: ${SYSTEM_ARCH}." >&2
        exit 1
        ;;
esac

ASSET_NAME="agy_cli_linux_${RELEASE_ARCH}.tar.gz"
TEMP_DIR="$(mktemp -d)"
ARCHIVE_PATH="${TEMP_DIR}/${ASSET_NAME}"

cleanup() {
    rm -rf -- "${TEMP_DIR}"
}
trap cleanup EXIT

install -d -m 0755 "${BIN_DIR}"

if command -v curl >/dev/null 2>&1; then
    DOWNLOADER="curl"
elif command -v wget >/dev/null 2>&1; then
    DOWNLOADER="wget"
else
    echo "Fatal: Either curl or wget is required but neither is installed." >&2
    exit 1
fi

fetch_url() {
    if [[ "${DOWNLOADER}" == "curl" ]]; then
        curl --fail --location --silent --show-error --retry 3 \
            --connect-timeout 10 \
            -H "Accept: application/vnd.github+json" \
            -A "sl-devcontainers-images-antigravity-feature" "$1"
    else
        wget --quiet --header="Accept: application/vnd.github+json" \
            --user-agent="sl-devcontainers-images-antigravity-feature" -O - "$1"
    fi
}

download_file() {
    if [[ "${DOWNLOADER}" == "curl" ]]; then
        curl --fail --location --silent --show-error --retry 3 \
            --connect-timeout 10 --output "$2" "$1"
    else
        wget --quiet --output-document="$2" "$1"
    fi
}

echo "(*) Resolving the latest Antigravity CLI release..."
RELEASE_JSON="$(fetch_url "${GITHUB_API_URL}")"
RELEASE_TAG="$(printf '%s\n' "${RELEASE_JSON}" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
GITHUB_DOWNLOAD_URL="$(printf '%s\n' "${RELEASE_JSON}" | sed -n 's|.*"browser_download_url"[[:space:]]*:[[:space:]]*"\(https://github\.com/google-antigravity/antigravity-cli/releases/download/[^\"]*/'"${ASSET_NAME}"'\)".*|\1|p')"

if [[ -z "${RELEASE_TAG}" || -z "${GITHUB_DOWNLOAD_URL}" ]]; then
    echo "Fatal: Could not find the latest Linux ${RELEASE_ARCH} Antigravity release asset (${ASSET_NAME})." >&2
    exit 1
fi

VERSION="${RELEASE_TAG#v}"
DOWNLOAD_URL="https://gh.hihsl.cn/${GITHUB_DOWNLOAD_URL}"

echo "(*) Downloading Antigravity CLI ${VERSION}..."
download_file "${DOWNLOAD_URL}" "${ARCHIVE_PATH}"

if ! tar -tzf "${ARCHIVE_PATH}" antigravity >/dev/null 2>&1; then
    echo "Fatal: The Antigravity release archive does not contain the antigravity binary." >&2
    exit 1
fi

tar -xzf "${ARCHIVE_PATH}" -C "${TEMP_DIR}" antigravity
install -m 0755 "${TEMP_DIR}/antigravity" "${BIN_DIR}/agy"

# Seed the mount point before the named volume is attached at container start.
install -d -m 0755 "${REMOTE_USER_HOME}/.gemini"
chown -R "${_REMOTE_USER}:${_REMOTE_USER}" "${REMOTE_USER_HOME}/.gemini"

"${BIN_DIR}/agy" --version >/dev/null

echo "Done!"
