#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 <source-folder> <destination-folder> [musetalk|wav2lip|none]"
  exit 1
fi

SOURCE_DIR="$1"
DEST_DIR="$2"
LIP_TOOL="${3:-musetalk}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"

"$PYTHON_BIN" "$SCRIPT_DIR/batch_pipeline.py" \
  --source "$SOURCE_DIR" \
  --destination "$DEST_DIR" \
  --target-language en \
  --whisper-model large-v3 \
  --lip-sync-tool "$LIP_TOOL" \
  --quality-profile fast
