#!/usr/bin/env bash
set -euo pipefail

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Installing GitHub CLI..."

install_lifecycle_script github-cli post-create

INSTALL_DIR="/usr/local/share/github-cli"
GITHUB_API_URL="https://api.github.com/repos/cli/cli/releases/latest"
GITHUB_RELEASE_MIRROR="${GITHUBRELEASEMIRROR-https://gh.hihsl.cn}"
SYSTEM_ARCH="$(uname -m)"

case "${SYSTEM_ARCH}" in
    x86_64 | amd64)
        RELEASE_ARCH="amd64"
        ;;
    aarch64 | arm64)
        RELEASE_ARCH="arm64"
        ;;
    *)
        echo "Fatal: Unsupported architecture: ${SYSTEM_ARCH}." >&2
        exit 1
        ;;
esac

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
            -A "sl-devcontainers-images-github-cli-feature" "$1"
    else
        wget --quiet --header="Accept: application/vnd.github+json" \
            --user-agent="sl-devcontainers-images-github-cli-feature" -O - "$1"
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

echo "(*) Resolving the latest GitHub CLI release..."
RELEASE_JSON="$(fetch_url "${GITHUB_API_URL}")"
RELEASE_TAG="$(printf '%s\n' "${RELEASE_JSON}" | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"

if [[ -z "${RELEASE_TAG}" || "${RELEASE_TAG}" != v* ]]; then
    echo "Fatal: Could not resolve the latest GitHub CLI release." >&2
    exit 1
fi

VERSION="${RELEASE_TAG#v}"
ASSET_NAME="gh_${VERSION}_linux_${RELEASE_ARCH}.tar.gz"
GITHUB_DOWNLOAD_URL="https://github.com/cli/cli/releases/download/${RELEASE_TAG}/${ASSET_NAME}"
if [[ -n "${GITHUB_RELEASE_MIRROR}" ]]; then
    DOWNLOAD_URL="${GITHUB_RELEASE_MIRROR%/}/${GITHUB_DOWNLOAD_URL}"
else
    DOWNLOAD_URL="${GITHUB_DOWNLOAD_URL}"
fi

TEMP_DIR="$(mktemp -d)"
ARCHIVE_PATH="${TEMP_DIR}/${ASSET_NAME}"

cleanup() {
    rm -rf -- "${TEMP_DIR}"
}
trap cleanup EXIT

echo "(*) Downloading GitHub CLI ${VERSION}..."
download_file "${DOWNLOAD_URL}" "${ARCHIVE_PATH}"

ARCHIVE_ROOT="gh_${VERSION}_linux_${RELEASE_ARCH}"
if ! tar -tzf "${ARCHIVE_PATH}" "${ARCHIVE_ROOT}/bin/gh" >/dev/null 2>&1; then
    echo "Fatal: The GitHub CLI release archive does not contain the gh binary." >&2
    exit 1
fi

install -d -m 0755 "${INSTALL_DIR}"
tar -xzf "${ARCHIVE_PATH}" -C "${INSTALL_DIR}" --strip-components=1
chmod 0755 "${INSTALL_DIR}/bin/gh"

"${INSTALL_DIR}/bin/gh" --version >/dev/null

echo "Done!"
