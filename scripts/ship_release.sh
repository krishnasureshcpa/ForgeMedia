#!/bin/bash
# scripts/ship_release.sh — Apple HIG-compliant release shipper.
#
# Policy enforced (per the Apple Engineering / Unified Design directive):
#   1. Exactly ONE ForgeMedia.app exists in the repo root at any time.
#   2. Every successful build silently provisions a production-ready clone to
#      /Applications/ForgeMedia.app (system mirror).
#   3. Pre-build history rotation: any prior .app / .dmg in the repo root is
#      archived to build-history/ with a UTC timestamp before being replaced.
#   4. Single canonical DMG companion.
#
# Idempotent. Safe to re-run.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="ForgeMedia"
BIN="$REPO_ROOT/.build/arm64-apple-macosx/release/${APP_NAME}App"
REPO_APP="$REPO_ROOT/${APP_NAME}.app"
REPO_DMG="$REPO_ROOT/${APP_NAME}.dmg"
SYSTEM_APP="/Applications/${APP_NAME}.app"
HISTORY_DIR="$REPO_ROOT/build-history"
ICON_SOURCE="/tmp/forgemedia_icon.icns"
INFO_PLIST="$REPO_ROOT/Sources/${APP_NAME}App/Info.plist"

if [ ! -f "$BIN" ]; then
    echo "[ship] ERROR: binary not found at $BIN" >&2
    echo "[ship] Run: swift build -c release --product ${APP_NAME}App" >&2
    exit 1
fi

if [ ! -f "$INFO_PLIST" ]; then
    echo "[ship] ERROR: Info.plist not found at $INFO_PLIST" >&2
    exit 1
fi

mkdir -p "$HISTORY_DIR"

# ---------- History rotation ----------
ts="$(date -u +%Y%m%dT%H%M%SZ)"
if [ -d "$REPO_APP" ]; then
    echo "[ship] archiving prior $REPO_APP → build-history/${APP_NAME}-${ts}.app"
    mv "$REPO_APP" "$HISTORY_DIR/${APP_NAME}-${ts}.app"
fi
if [ -f "$REPO_DMG" ]; then
    echo "[ship] archiving prior $REPO_DMG → build-history/${APP_NAME}-${ts}.dmg"
    mv "$REPO_DMG" "$HISTORY_DIR/${APP_NAME}-${ts}.dmg"
fi
# Prune history older than 30 days to keep build-history/ bounded
find "$HISTORY_DIR" -maxdepth 1 -name "${APP_NAME}-*" -mtime +30 -exec rm -rf {} + 2>/dev/null || true

# ---------- Assemble canonical app bundle ----------
echo "[ship] building $REPO_APP"
mkdir -p "$REPO_APP/Contents/MacOS" "$REPO_APP/Contents/Resources"
cp "$BIN" "$REPO_APP/Contents/MacOS/${APP_NAME}App"
cp "$INFO_PLIST" "$REPO_APP/Contents/Info.plist"
chmod +x "$REPO_APP/Contents/MacOS/${APP_NAME}App"

if [ -f "$ICON_SOURCE" ]; then
    cp "$ICON_SOURCE" "$REPO_APP/Contents/Resources/AppIcon.icns"
    echo "[ship] icon installed: $REPO_APP/Contents/Resources/AppIcon.icns"
fi

# Ad-hoc sign so timestamps / attributes are signed consistently
codesign --force --deep --sign - "$REPO_APP" >/dev/null 2>&1 || true
codesign --verify --verbose=2 "$REPO_APP" 2>&1 | sed 's/^/[ship]   /'

# ---------- System mirror ----------
echo "[ship] mirroring to $SYSTEM_APP"
rm -rf "$SYSTEM_APP"
cp -R "$REPO_APP" "$SYSTEM_APP"
codesign --force --deep --sign - "$SYSTEM_APP" >/dev/null 2>&1 || true

# ---------- DMG companion ----------
echo "[ship] building DMG"
hdiutil create -volname "${APP_NAME}" -srcfolder "$REPO_APP" -ov -format UDZO "$REPO_DMG" 2>&1 | sed 's/^/[ship]   /'
hdiutil verify "$REPO_DMG" 2>&1 | tail -3 | sed 's/^/[ship]   /'

# ---------- Inventory ----------
echo "[ship] ============================================"
echo "[ship] Binary : $BIN ($(stat -f%z "$BIN") bytes)"
echo "[ship] Repo app: $REPO_APP"
echo "[ship] Sys app : $SYSTEM_APP"
echo "[ship] DMG     : $REPO_DMG ($(stat -f%z "$REPO_DMG") bytes)"
echo "[ship] History : $(ls -1 "$HISTORY_DIR" 2>/dev/null | wc -l | tr -d ' ') archived artifacts"
echo "[ship] ============================================"