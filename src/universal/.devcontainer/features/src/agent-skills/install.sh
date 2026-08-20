#!/usr/bin/env bash
set -e

source /usr/local/share/devcontainer-features/utils/utils.sh

echo "(*) Installing Agent Skills..."

# Begin agent-browser skill installation.
# Install Puppeteer without its postinstall download. Chrome is installed
# explicitly below so the download mirror and cache location are deterministic.
run_as_remote_user \
    PUPPETEER_SKIP_DOWNLOAD=true \
    pnpm -y add -g --allow-build=puppeteer puppeteer

# Keep Chrome in Puppeteer's default cache for the remote user. agent-browser
# searches this location automatically, so no executable-path override is needed.
REMOTE_USER_HOME="$(get_remote_user_home)"
PUPPETEER_CACHE_DIR="${REMOTE_USER_HOME}/.cache/puppeteer"
CHROME_DOWNLOAD_BASE_URL="${PUPPETEER_CHROME_DOWNLOAD_BASE_URL:-${PUPPETEER_DOWNLOAD_BASE_URL:-${CHROMEDOWNLOADBASEURL:-https://cdn.npmmirror.com/binaries/chrome-for-testing}}}"

run_as_remote_user mkdir -p "${PUPPETEER_CACHE_DIR}"

# Puppeteer's dependency installation requires root on Debian-based images.
apt-get update
PUPPETEER_CACHE_DIR="${PUPPETEER_CACHE_DIR}" \
    puppeteer browsers install chrome \
        --base-url "${CHROME_DOWNLOAD_BASE_URL}" \
        --install-deps
apt-get clean
rm -rf /var/lib/apt/lists/*

# The browser was installed as root so that Puppeteer could install its system
# dependencies. Return cache ownership to the user that runs agent-browser.
chown -R "${_REMOTE_USER}" "${PUPPETEER_CACHE_DIR}"

# Install the agent-browser CLI globally as the remote user.
run_as_remote_user pnpm -y add -g --allow-build=agent-browser agent-browser

# Install the skill in the remote user's home for the same reason.
run_as_remote_user pnpx -y skills add https://github.com/vercel-labs/agent-browser \
    --skill agent-browser -y -g -a codex
# End agent-browser skill installation.

echo "Done!"
