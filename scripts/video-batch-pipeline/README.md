# ForgeMedia Recursive Dubbing Pipeline

This backend preserves the existing app UI while replacing translation execution with a modern local batch architecture:

1. WhisperX diarization + `.srt` subtitle generation
2. open_dubbing translation + English dubbing audio generation
3. Visual lip sync with MuseTalk or Wav2Lip
4. FFmpeg multiplexing + subtitle burn-in

## Install (local, free, open-source)

```bash
pip install whisperx open_dubbing tqdm
# install MuseTalk or Wav2Lip separately in local repos/environments
# install ffmpeg (brew install ffmpeg on macOS)
```

## Run recursively with folder structure preservation

```bash
scripts/video-batch-pipeline/process_folder.sh \
  /path/to/source_videos \
  /path/to/output_videos \
  musetalk
```

The output folder mirrors the source folder tree exactly. Each processed file keeps the same base name as the source and writes:

- `<same-name>.mp4` (dubbed + lip-synced + burned subtitles)
- `<same-name>.srt` (English sidecar subtitles)

## Reliability behavior

- Per-file `try/except` guards prevent a single bad file from crashing the batch.
- Progress is visible with `tqdm` and stage logs (`[FILE]`, `[STEP]`, `[DONE]`, `[ERROR]`).
- End-of-run report is written to `pipeline_summary.json`.
