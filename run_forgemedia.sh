#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT_DIR"

MODE=""
INPUT=""
PRESET="convert_h264"
RECURSIVE_FLAG="--recursive"

# Fast path: pass-through args directly
if [ "$#" -gt 0 ]; then
  swift build --product ForgeMediaCLI >/dev/null
  exec .build/arm64-apple-macosx/debug/ForgeMediaCLI "$@"
fi

# Interactive path
read -r -p "Mode (single|multi|folder) [folder]: " MODE
MODE="${MODE:-folder}"

read -r -p "Input path (file, comma-list, or folder): " INPUT
if [ -z "$INPUT" ]; then
  echo "Input is required."
  exit 1
fi

read -r -p "Preset [convert_h264]: " PRESET
PRESET="${PRESET:-convert_h264}"

if [ "$MODE" = "folder" ]; then
  read -r -p "Recursive? (y/n) [y]: " RECURSIVE
  RECURSIVE="${RECURSIVE:-y}"
  if [ "$RECURSIVE" = "n" ] || [ "$RECURSIVE" = "N" ]; then
    RECURSIVE_FLAG="--no-recursive"
  fi
fi

swift build --product ForgeMediaCLI >/dev/null

if [ "$MODE" = "folder" ]; then
  exec .build/arm64-apple-macosx/debug/ForgeMediaCLI \
    --mode "$MODE" \
    --input "$INPUT" \
    "$RECURSIVE_FLAG" \
    --preset "$PRESET"
else
  exec .build/arm64-apple-macosx/debug/ForgeMediaCLI \
    --mode "$MODE" \
    --input "$INPUT" \
    --preset "$PRESET"
fi
