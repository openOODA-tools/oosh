#!/bin/bash
# ==============================================================================
# oosh Pacman / Arch Installer Script
# ==============================================================================
set -euo pipefail

VERSION="1.0.0"
RELEASE="1"
ARCH="x86_64"
PKG_NAME="oosh-${VERSION}-${RELEASE}-${ARCH}.pkg.tar.zst"
PKG_URL="https://github.com/openOODA-tools/oosh/releases/download/v${VERSION}/${PKG_NAME}"

echo "==> oosh Pacman Installer (v${VERSION})"

if ! command -v pacman >/dev/null 2>&1; then
    echo "ERROR: pacman was not found on this system." >&2
    exit 1
fi

TMP_DIR="$(mktemp -d /tmp/oosh-pacman.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Fetching ${PKG_NAME}..."
curl -fsSL "$PKG_URL" -o "${TMP_DIR}/${PKG_NAME}"

echo "==> Installing via pacman..."
if [ "$(id -u)" -eq 0 ]; then
    pacman -U --noconfirm "${TMP_DIR}/${PKG_NAME}"
else
    sudo pacman -U --noconfirm "${TMP_DIR}/${PKG_NAME}"
fi

echo "==> Verifying shell registration in /etc/shells..."
OOSH_BIN="/usr/bin/oosh"
if [ -f /etc/shells ]; then
    if ! grep -q "^${OOSH_BIN}$" /etc/shells 2>/dev/null; then
        echo "==> Registering ${OOSH_BIN} in /etc/shells..."
        if [ "$(id -u)" -eq 0 ]; then
            echo "${OOSH_BIN}" >> /etc/shells
        else
            echo "${OOSH_BIN}" | sudo tee -a /etc/shells >/dev/null
        fi
    fi
    echo "✔ ${OOSH_BIN} registered in /etc/shells"
fi

echo "==> Verifying installation..."
oosh --version
echo "==> oosh v${VERSION} successfully installed via Pacman."
