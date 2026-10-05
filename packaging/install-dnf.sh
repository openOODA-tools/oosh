#!/bin/bash
# ==============================================================================
# oosh DNF / RPM Installer Script
# ==============================================================================
set -euo pipefail

VERSION="1.0.0"
RELEASE="1"
ARCH="x86_64"
RPM_NAME="oosh-${VERSION}-${RELEASE}.${ARCH}.rpm"
RPM_URL="https://github.com/openOODA-tools/oosh/releases/download/v${VERSION}/${RPM_NAME}"

echo "==> oosh DNF / RPM Installer (v${VERSION})"

if ! command -v dnf >/dev/null 2>&1 && ! command -v rpm >/dev/null 2>&1; then
    echo "ERROR: Neither dnf nor rpm was found on this system." >&2
    exit 1
fi

TMP_DIR="$(mktemp -d /tmp/oosh-dnf.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Fetching ${RPM_NAME}..."
curl -fsSL "$RPM_URL" -o "${TMP_DIR}/${RPM_NAME}"

if command -v dnf >/dev/null 2>&1; then
    echo "==> Installing via dnf..."
    if [ "$(id -u)" -eq 0 ]; then
        dnf install -y "${TMP_DIR}/${RPM_NAME}"
    else
        sudo dnf install -y "${TMP_DIR}/${RPM_NAME}"
    fi
else
    echo "==> Installing via rpm..."
    if [ "$(id -u)" -eq 0 ]; then
        rpm -Uvh --replacepkgs "${TMP_DIR}/${RPM_NAME}"
    else
        sudo rpm -Uvh --replacepkgs "${TMP_DIR}/${RPM_NAME}"
    fi
fi

echo "==> Verifying installation..."
oosh --version
echo "==> oosh v${VERSION} successfully installed via RPM/DNF."
