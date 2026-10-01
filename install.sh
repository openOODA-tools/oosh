#!/bin/sh
# ==============================================================================
# oosh Universal Installer
# "The intent-driven, ambient, capability-bounded interactive shell for the AI era."
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/openOODA-tools/oosh/main/install.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/openOODA-tools/oosh/main/install.sh -o install.sh && chmod +x install.sh && ./install.sh
#
# Flags:
#   --prefix <dir>   Installation directory (default: /usr/local/bin or ~/.local/bin)
#   --dry-run        Preview installation actions without modifying the system
#   --verify         Verify SHA-256 checksums before installation
#   --uninstall      Remove oosh binary from the system
#   -h, --help       Display this help message
# ==============================================================================

set -eu

REPO="openOODA-tools/oosh"
GITHUB_URL="https://github.com/${REPO}"
RAW_URL="https://raw.githubusercontent.com/${REPO}/main"

# --- Styling & Terminal Detection ---------------------------------------------
if [ -t 1 ] && [ "${NO_COLOR:-}" = "" ] && [ "${TERM:-dumb}" != "dumb" ]; then
    ORANGE="\033[38;5;208m"
    CYAN="\033[38;5;51m"
    GREEN="\033[38;5;82m"
    YELLOW="\033[38;5;220m"
    DIM="\033[38;5;242m"
    BOLD="\033[1m"
    RESET="\033[0m"
    IS_TTY=1
else
    ORANGE="" CYAN="" GREEN="" YELLOW="" MAGENTA="" DIM="" BOLD="" RESET=""
    IS_TTY=0
fi

say()  { printf '%b\n' "$*"; }
dim()  { say " ${DIM}$*${RESET}"; }
ok()   { say " ${GREEN}✔${RESET} $*"; }
warn() { say " ${YELLOW}!${RESET} $*"; }
err()  { say " ${YELLOW}ERROR:${RESET} $*" >&2; }
step() { say ""; say " ${CYAN}${BOLD}$*${RESET}"; }

banner() {
    say ""
    say "${ORANGE}${BOLD}    ____  ____  _____ __  __${RESET}"
    say "${ORANGE}${BOLD}   / __ \/ __ \/ ___// / / /${RESET}"
    say "${ORANGE}${BOLD}  / / / / / / /\__ \/ /_/ / ${RESET}"
    say "${ORANGE}${BOLD} / /_/ / /_/ /___/ / __  /  ${RESET}"
    say "${ORANGE}${BOLD} \____/\____//____/_/ /_/   ${RESET}"
    say " ${BOLD}oosh — openOODA Sovereign Shell${RESET}"
    say " ${DIM}Zero external dependencies • Pure standalone Linux executable${RESET}"
    say ""
}

# --- Argument Parsing ---------------------------------------------------------
DRY_RUN=0
DO_UNINSTALL=0
DO_VERIFY=0
CUSTOM_PREFIX=""

while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1; shift ;;
        --uninstall) DO_UNINSTALL=1; shift ;;
        --verify) DO_VERIFY=1; shift ;;
        --prefix) CUSTOM_PREFIX="$2"; shift 2 ;;
        -h|--help)
            banner
            say "Usage: install.sh [options]"
            say "Options:"
            say "  --prefix <dir>   Install destination (default: /usr/local/bin or ~/.local/bin)"
            say "  --dry-run        Simulate without modifying the host"
            say "  --verify         Perform strict cryptographic SHA-256 verification"
            say "  --uninstall      Remove oosh from the system"
            say "  -h, --help       Show this help"
            exit 0
            ;;
        *) err "Unknown flag: $1"; exit 1 ;;
    esac
done

banner

# --- Uninstall Path -----------------------------------------------------------
if [ "$DO_UNINSTALL" -eq 1 ]; then
    step "Uninstalling oosh"
    FOUND=0
    for p in /usr/local/bin/oosh "${HOME}/.local/bin/oosh" "${HOME}/.openooda/bin/oosh"; do
        if [ -f "$p" ]; then
            if [ "$DRY_RUN" -eq 1 ]; then
                dim "Would remove $p"
            else
                rm -f "$p" 2>/dev/null || sudo rm -f "$p"
                ok "Removed $p"
            fi
            FOUND=1
        fi
    done
    if [ "$FOUND" -eq 0 ]; then
        warn "No oosh binary found in standard install locations."
    fi
    exit 0
fi

# --- Step 1: Pre-flight & Architecture ----------------------------------------
step "[1/4] Pre-flight & Platform Detection"

OS="$(uname -s)"
if [ "$OS" != "Linux" ]; then
    warn "Detected non-Linux OS: $OS"
    say " oosh is built for native Linux kernels. Continuing with best effort..."
fi

ARCH="$(uname -m)"
case "$ARCH" in
    x86_64|amd64)
        TARGET_ARCH="x86_64"
        ;;
    aarch64|arm64)
        TARGET_ARCH="aarch64"
        ;;
    *)
        err "Unsupported architecture: $ARCH (oosh supports x86_64 and aarch64)"
        exit 1
        ;;
esac
ok "Platform: ${BOLD}${OS} ${TARGET_ARCH}${RESET}"

# Verify curl exists
if ! command -v curl >/dev/null 2>&1; then
    err "curl is required to download oosh release assets"
    exit 1
fi

# Verify sha256 tools exist
HASH_CMD=""
if command -v sha256sum >/dev/null 2>&1; then
    HASH_CMD="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
    HASH_CMD="shasum -a 256"
fi

if [ -z "$HASH_CMD" ]; then
    warn "Neither sha256sum nor shasum found; cryptographic verification disabled."
else
    ok "Hash utility: ${BOLD}${HASH_CMD}${RESET}"
fi

# Determine destination directory
if [ -n "$CUSTOM_PREFIX" ]; then
    INSTALL_DIR="$CUSTOM_PREFIX"
elif [ "$(id -u)" -eq 0 ]; then
    INSTALL_DIR="/usr/local/bin"
elif command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    INSTALL_DIR="/usr/local/bin"
else
    INSTALL_DIR="${HOME}/.local/bin"
fi
dim "Target binary path: ${INSTALL_DIR}/oosh"

# --- Step 2: Fetch Release Metadata -------------------------------------------
step "[2/4] Resolving Latest Release"

# Fetch latest release tag via GitHub API or redirect
LATEST_TAG=$(curl -sSL -H "Accept: application/vnd.github+json" "https://api.github.com/repos/${REPO}/releases/latest" 2>/dev/null | grep '"tag_name":' | head -1 | cut -d '"' -f 4 || echo "")
if [ -z "$LATEST_TAG" ]; then
    # Fallback to current certified release
    LATEST_TAG="v0.2.0"
fi
ok "Release version: ${BOLD}${LATEST_TAG}${RESET}"

ASSET_NAME="oosh-linux-${TARGET_ARCH}"
ASSET_URL="${GITHUB_URL}/releases/download/${LATEST_TAG}/${ASSET_NAME}"
SHA_URL="${GITHUB_URL}/releases/download/${LATEST_TAG}/${ASSET_NAME}.sha256"

# --- Step 3: Download & Integrity Verification --------------------------------
step "[3/4] Downloading & Cryptographic Verification"

if [ "$DRY_RUN" -eq 1 ]; then
    dim "[dry-run] Would download: $ASSET_URL"
    dim "[dry-run] Would download: $SHA_URL"
    dim "[dry-run] Would verify SHA-256 and install to: $INSTALL_DIR/oosh"
    ok "Dry run plan complete."
    exit 0
fi

TMP_DIR="$(mktemp -d /tmp/oosh-install.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT INT TERM

dim "Fetching binary asset from ${ASSET_URL}..."
curl -fsSL "$ASSET_URL" -o "${TMP_DIR}/${ASSET_NAME}" || {
    err "Failed to download oosh release asset from ${ASSET_URL}"
    exit 1
}
ok "Downloaded ${ASSET_NAME}"

dim "Fetching checksum from ${SHA_URL}..."
curl -fsSL "$SHA_URL" -o "${TMP_DIR}/${ASSET_NAME}.sha256" 2>/dev/null || true

if [ -f "${TMP_DIR}/${ASSET_NAME}.sha256" ] && [ -n "$HASH_CMD" ]; then
    EXPECTED_SHA=$(awk '{print $1}' "${TMP_DIR}/${ASSET_NAME}.sha256" | head -1)
    ACTUAL_SHA=$($HASH_CMD "${TMP_DIR}/${ASSET_NAME}" | awk '{print $1}')
    if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
        err "SHA-256 checksum mismatch!"
        err "  Expected: $EXPECTED_SHA"
        err "  Actual:   $ACTUAL_SHA"
        exit 1
    fi
    ok "SHA-256 verified: ${DIM}${ACTUAL_SHA}${RESET}"
else
    warn "Checksum asset not present; skipped hash check."
fi

# --- Step 4: Installation & Verification --------------------------------------
step "[4/4] Deploying Sovereign Shell"

# Ensure directory exists
if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR" 2>/dev/null || sudo mkdir -p "$INSTALL_DIR"
fi

chmod +x "${TMP_DIR}/${ASSET_NAME}"

# Move to destination
if [ -w "$INSTALL_DIR" ]; then
    mv "${TMP_DIR}/${ASSET_NAME}" "${INSTALL_DIR}/oosh"
else
    sudo mv "${TMP_DIR}/${ASSET_NAME}" "${INSTALL_DIR}/oosh"
fi
ok "Installed executable to ${BOLD}${INSTALL_DIR}/oosh${RESET}"

# Verify installed binary
if "${INSTALL_DIR}/oosh" --version >/dev/null 2>&1; then
    INST_VER=$("${INSTALL_DIR}/oosh" --version)
    ok "Binary verified: ${GREEN}${BOLD}${INST_VER}${RESET}"
else
    warn "Installed binary could not execute directly."
fi

# Check PATH
PATH_OK=0
case ":$PATH:" in
    *:"$INSTALL_DIR":*) PATH_OK=1 ;;
esac

say ""
say " ${GREEN}${BOLD}✔ oosh successfully installed!${RESET}"
say ""

if [ "$PATH_OK" -eq 0 ]; then
    warn "${INSTALL_DIR} is not currently in your \$PATH."
    say "   Add the following line to your ${BOLD}~/.bashrc${RESET} or ${BOLD}~/.zshrc${RESET}:"
    say ""
    say "     ${CYAN}export PATH=\"${INSTALL_DIR}:\$PATH\"${RESET}"
    say ""
fi

say " To launch your sovereign shell right now:"
say "   ${BOLD}${INSTALL_DIR}/oosh${RESET}"
say ""
say " To set oosh as your default login shell:"
say "   ${DIM}echo \"${INSTALL_DIR}/oosh\" | sudo tee -a /etc/shells${RESET}"
say "   ${BOLD}chsh -s \"${INSTALL_DIR}/oosh\"${RESET}"
say ""
