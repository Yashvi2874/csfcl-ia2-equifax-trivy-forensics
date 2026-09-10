#!/usr/bin/env bash
#
# install-trivy.sh
#
# Installs the Trivy binary into ~/bin. No administrator or sudo rights needed,
# nothing is written outside your home directory, and no system settings change.
#
# To remove Trivy afterwards:
#   rm -rf ~/bin/trivy ~/bin/trivy.exe ~/.cache/trivy
#
# Usage:  bash scripts/install-trivy.sh
#
set -euo pipefail

TRIVY_VERSION="0.74.0"   # pinned so every group member scans with the same tool

log()  { printf '\n==> %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*"; }

# ----------------------------------------------------------- detect platform
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  MINGW*|MSYS*|CYGWIN*)
    ASSET="trivy_${TRIVY_VERSION}_windows-64bit.zip"
    BINARY="trivy.exe"
    ;;
  Darwin)
    if [ "$ARCH" = "arm64" ]; then
      ASSET="trivy_${TRIVY_VERSION}_macOS-ARM64.tar.gz"   # Apple Silicon (M1-M4)
    else
      ASSET="trivy_${TRIVY_VERSION}_macOS-64bit.tar.gz"   # Intel Macs
    fi
    BINARY="trivy"
    ;;
  Linux)
    ASSET="trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz"
    BINARY="trivy"
    ;;
  *)
    warn "Unsupported platform: $OS"
    exit 1
    ;;
esac

URL="https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/${ASSET}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

log "Platform: $OS / $ARCH"
printf '    Asset : %s\n' "$ASSET"

# ------------------------------------------------------------------ download
log "Downloading Trivy v${TRIVY_VERSION}"
if ! curl -fsSL --max-time 300 -o "$TMP/$ASSET" "$URL"; then
  warn "Download failed. Check your internet connection, then retry."
  exit 1
fi

# A GitHub 404 returns a tiny HTML page rather than an archive, so check size.
SIZE="$(wc -c < "$TMP/$ASSET" | tr -d ' ')"
if [ "$SIZE" -lt 1000000 ]; then
  warn "Downloaded file is only ${SIZE} bytes - that is not a Trivy release."
  warn "The pinned version may have been withdrawn. Check:"
  warn "  https://github.com/aquasecurity/trivy/releases"
  exit 1
fi
printf '    Downloaded %s bytes\n' "$SIZE"

# ------------------------------------------------------------------- extract
log "Extracting"
case "$ASSET" in
  *.zip)    unzip -o -q "$TMP/$ASSET" -d "$TMP" ;;
  *.tar.gz) tar -xzf "$TMP/$ASSET" -C "$TMP" ;;
esac

if [ ! -f "$TMP/$BINARY" ]; then
  warn "Expected $BINARY inside the archive but did not find it."
  exit 1
fi

# ------------------------------------------------------------------- install
mkdir -p "$HOME/bin"
cp "$TMP/$BINARY" "$HOME/bin/$BINARY"
chmod +x "$HOME/bin/$BINARY"

log "Installed"
printf '    Location : %s\n' "$HOME/bin/$BINARY"
printf '    Version  : %s\n' "$("$HOME/bin/$BINARY" --version 2>/dev/null | head -1)"

# macOS blocks unsigned downloaded binaries until they are cleared by Gatekeeper.
if [ "$OS" = "Darwin" ]; then
  printf '\n'
  printf '    macOS note: if you see "cannot be opened because the developer\n'
  printf '    cannot be verified", clear the quarantine flag with:\n'
  printf '        xattr -d com.apple.quarantine ~/bin/trivy\n'
fi

printf '\n    Next: bash scripts/run-investigation.sh\n\n'
