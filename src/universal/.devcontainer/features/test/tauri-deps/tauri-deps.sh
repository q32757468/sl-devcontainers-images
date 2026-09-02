#!/usr/bin/env bash

source dev-container-features-test-lib

check "tauri-system-dependencies" bash -c '
    set -e
    for package in \
        libwebkit2gtk-4.1-dev \
        build-essential \
        curl \
        wget \
        file \
        libxdo-dev \
        libssl-dev \
        libayatana-appindicator3-dev \
        librsvg2-dev; do
        dpkg-query -W -f='"'"'${Status}\n'"'"' "${package}" \
            | grep -Fqx '"'"'install ok installed'"'"'
    done
'

reportResults
