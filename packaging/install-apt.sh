#!/bin/bash
# ==============================================================================
# oosh APT / DEB Installer Script
# ==============================================================================
set -euo pipefail

VERSION="1.0.0"
DEB_NAME="oosh_${VERSION}-1_amd64.deb"
DEB_URL="https://github.com/openOODA-tools/oosh/releases/download/v${VERSION}/${DEB_NAME}"

echo "==> oosh APT / DEB Installer (v${VERSION})"

if ! command -v apt >/dev/null 2>&1 && ! command -v dpkg >/dev/null 2>&1; then
    echo "ERROR: Neither apt nor dpkg was found on this system." >&2
    exit 1
fi

TMP_DIR="$(mktemp -d /tmp/oosh-apt.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Fetching ${DEB_NAME}..."
curl -fsSL "$DEB_URL" -o "${TMP_DIR}/${DEB_NAME}"

if command -v apt >/dev/null 2>&1; then
    echo "==> Installing via apt..."
    if [ "$(id -u)" -eq 0 ]; then
        apt install -y "${TMP_DIR}/${DEB_NAME}"
    else
        sudo apt install -y "${TMP_DIR}/${DEB_NAME}"
    fi
else
    echo "==> Installing via dpkg..."
    if [ "$(id -u)" -eq 0 ]; then
        dpkg -i "${TMP_DIR}/${DEB_NAME}"
    else
        sudo dpkg -i "${TMP_DIR}/${DEB_NAME}"
    fi
fi

echo "==> Verifying installation..."
oosh --version
echo "==> oosh v${VERSION} successfully installed via APT/DEB."
