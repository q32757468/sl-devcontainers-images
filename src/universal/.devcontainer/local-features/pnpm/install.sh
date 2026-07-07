#!/usr/bin/env bash
set -e

PNPM_HOME=${PNPM_HOME:-"/usr/local/share/pnpm"}

echo "(*) Installing pnpm..."

curl -fsSL https://get.pnpm.io/install.sh | env PNPM_HOME="${PNPM_HOME}" SHELL="$(which bash)" bash -

# Ensure pnpm global directories are writable by non-root users
chmod -R a+w ${PNPM_HOME}

# Make pnpm available system-wide
echo "export PNPM_HOME=${PNPM_HOME}" > /etc/profile.d/pnpm.sh
echo 'export PATH=$PNPM_HOME/bin:$PNPM_HOME:$PATH' >> /etc/profile.d/pnpm.sh
chmod +x /etc/profile.d/pnpm.sh

# Also link into PATH for current sessions
ln -sf ${PNPM_HOME}/bin/pnpm /usr/local/bin/pnpm

echo "Done!"
