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

echo "==> Verifying shell registration in /etc/shells..."
OOSH_BIN="/usr/bin/oosh"
if [ -f /etc/shells ]; then
    if ! grep -q "^${OOSH_BIN}$" /etc/shells 2>/dev/null; then
        echo "==> Registering ${OOSH_BIN} in /etc/shells..."
        if [ "$(id -u)" -eq 0 ]; then
            if command -v add-shell >/dev/null 2>&1; then
                add-shell "${OOSH_BIN}"
            else
                echo "${OOSH_BIN}" >> /etc/shells
            fi
        else
            if command -v add-shell >/dev/null 2>&1; then
                sudo add-shell "${OOSH_BIN}"
            else
                echo "${OOSH_BIN}" | sudo tee -a /etc/shells >/dev/null
            fi
        fi
    fi
    echo "✔ ${OOSH_BIN} registered in /etc/shells"
fi

echo "==> Pruning redundant user-local shadow binaries if present..."
for u_home in "${HOME:-}" "${SUDO_USER:+$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)}"; do
    if [ -n "$u_home" ] && [ -d "$u_home" ]; then
        for shadow_bin in "${u_home}/.local/bin/oosh" "${u_home}/.openooda/bin/oosh"; do
            if [ -f "$shadow_bin" ]; then
                echo "==> Pruning redundant shadow binary at ${shadow_bin}..."
                rm -f "$shadow_bin" 2>/dev/null || sudo rm -f "$shadow_bin" 2>/dev/null || true
            fi
        done
    fi
done

echo "==> Verifying installation..."
oosh --version
echo "==> oosh v${VERSION} successfully installed via APT/DEB."
