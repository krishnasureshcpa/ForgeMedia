#!/bin/bash
# scripts/bundle_app.sh — Assemble ForgeMedia.app from SwiftPM release build.
# Usage: bash scripts/bundle_app.sh
#
# Assumes:
#   - `swift build -c release --product ForgeMediaApp` has been run
#   - Info.plist is at Sources/ForgeMediaApp/Info.plist
#   - HOME is set (typically ~/Applications/ is the install target)
#
# Idempotent: removes the existing .app before re-assembling.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BIN="$REPO_ROOT/.build/arm64-apple-macosx/release/ForgeMediaApp"
APP="${FORGEMEDIA_APP_PATH:-$HOME/Applications/ForgeMedia.app}"
INFO_PLIST="$REPO_ROOT/Sources/ForgeMediaApp/Info.plist"

if [ ! -f "$BIN" ]; then
    echo "[bundle] ERROR: binary not found at $BIN" >&2
    echo "[bundle] Run: swift build -c release --product ForgeMediaApp" >&2
    exit 1
fi

if [ ! -f "$INFO_PLIST" ]; then
    echo "[bundle] ERROR: Info.plist not found at $INFO_PLIST" >&2
    exit 1
fi

echo "[bundle] Removing existing app: $APP"
rm -rf "$APP"

echo "[bundle] Creating bundle layout"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

echo "[bundle] Copying binary"
cp "$BIN" "$APP/Contents/MacOS/ForgeMediaApp"

echo "[bundle] Copying Info.plist"
cp "$INFO_PLIST" "$APP/Contents/Info.plist"

echo "[bundle] Setting executable permission"
chmod +x "$APP/Contents/MacOS/ForgeMediaApp"

echo "[bundle] Done: $APP"
echo "[bundle] Binary size:"
ls -lh "$APP/Contents/MacOS/ForgeMediaApp" | awk '{print $5, $9}'