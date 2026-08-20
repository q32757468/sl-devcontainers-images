#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive

echo "(*) Preparing local Feature test base..."

sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirrors.aliyun.com/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources
sed -i 's|http://security.ubuntu.com/ubuntu/|http://mirrors.aliyun.com/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources
sed -i 's/^Components:.*/Components: main universe/' /etc/apt/sources.list.d/ubuntu.sources

apt-get update
apt-get -y install --no-install-recommends ca-certificates curl git jq python3 sudo
apt-get clean

if id ubuntu >/dev/null 2>&1; then
    usermod -aG sudo ubuntu
    printf '%s\n' 'ubuntu ALL=(root) NOPASSWD:ALL' > /etc/sudoers.d/ubuntu
    chmod 0440 /etc/sudoers.d/ubuntu
fi

echo "Done!"
