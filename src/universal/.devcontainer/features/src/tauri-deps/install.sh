#!/usr/bin/env bash
set -euo pipefail

echo "(*) Installing Tauri system dependencies..."

TAURI_PACKAGES=(
    libwebkit2gtk-4.1-dev
    build-essential
    curl
    wget
    file
    libxdo-dev
    libssl-dev
    libayatana-appindicator3-dev
    librsvg2-dev
)

MISSING_PACKAGES=()
for package in "${TAURI_PACKAGES[@]}"; do
    if ! dpkg-query -W -f='${Status}\n' "${package}" 2>/dev/null \
        | grep -Fqx 'install ok installed'; then
        MISSING_PACKAGES+=("${package}")
    fi
done

if ((${#MISSING_PACKAGES[@]} == 0)); then
    echo "All Tauri system dependencies are already installed."
else
    echo "Installing missing packages: ${MISSING_PACKAGES[*]}"
    apt-get update
    apt-get install -y --no-install-recommends \
        "${MISSING_PACKAGES[@]}"
    apt-get clean
    rm -rf /var/lib/apt/lists/*
fi

echo "Done!"
