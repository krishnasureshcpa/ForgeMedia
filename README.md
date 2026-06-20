# ForgeMedia

Privacy-first, offline-native macOS media command center for long-form creators, archivists, and studios.

**Your media stays on your Mac. No telemetry. No analytics. No cloud uploads by default.**

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/license-local--dev-lightgrey)

---

## Features

- **Drag & drop job queue** — drop videos directly onto the app window
- **Live progress tracking** — 10-state job lifecycle with named phase labels
- **FFmpeg-powered** — uses Homebrew FFmpeg; AVFoundation for native paths
- **Privacy On by default** — no network calls, no crash reporters, no remote AI
- **Menu bar status item** — monitor active jobs without switching apps
- **CLI tool (`fm`)** — scriptable batch processing from the terminal

---

## Requirements

- macOS 14 or later (Apple Silicon recommended)
- [FFmpeg](https://ffmpeg.org/download.html) via Homebrew: `brew install ffmpeg`
- Swift 6.0+ (Xcode Command Line Tools or full Xcode)

---

## Quick Start

### macOS App (GUI)

1. **Open** `ForgeMedia.app` from the project directory (double-click or `open ForgeMedia.app`)
2. **Drop** video files onto the window, or click **Select Video** / **Select Folder**
3. **Pick a preset** from the top-right picker and watch the live progress stream

The main window appears automatically on every launch. Closing the window keeps the app alive in the menu bar; click the `film` icon to reopen it.

### Command Line (`fm`)

Build and install the CLI in one step:

```bash
cd /path/to/ForgeMedia
swift build --product ForgeMediaCLI
cp .build/arm64-apple-macosx/debug/ForgeMediaCLI ~/.local/bin/fm
```

Process a single file:

```bash
fm video.mp4                               # convert to H.264 (default)
fm video.mp4 --preset convert_hevc         # convert to H.265
fm video.mp4 --preset transcribe           # extract transcript
```

Process a folder recursively:

```bash
fm /path/to/videos --recursive --preset convert_h264
```

Run interactively (menu-guided):

```bash
fm
```

---

## Building from Source

```bash
git clone https://github.com/krishnasureshcpa/ForgeMedia.git
cd ForgeMedia
swift package resolve
swift build --product ForgeMediaApp    # GUI app
swift build --product ForgeMediaCLI    # CLI tool
```

Build the app bundle and re-sign for local use:

```bash
swift build --product ForgeMediaApp
/bin/cp -f .build/arm64-apple-macosx/debug/ForgeMediaApp ForgeMedia.app/Contents/MacOS/ForgeMediaApp
codesign --force --sign - --deep ForgeMedia.app
open ForgeMedia.app
```

---

## Presets

| ID | Description |
|----|-------------|
| `convert_h264` | Re-encode to H.264/AAC MP4 (default) |
| `convert_hevc` | Re-encode to H.265/AAC MP4 |
| `transcribe` | Extract audio transcript via Whisper |
| `dub_translate_en` | Dub + translate to English (open-dubbing pipeline) |
| `stitch` | Concatenate multiple clips |
| `merge_audio` | Replace audio track |

---

## Architecture

```
ForgeMedia
├── ForgeMediaApp        — SwiftUI app entry, WindowGroup, MenuBarExtra, AppDelegate
├── ForgeMediaUI         — Shared SwiftUI views (JobCardView, ActivityStreamView, tokens)
├── ForgeMediaDomain     — Job models, presets, privacy policy, protocols
├── ForgeMediaData       — GRDB SQLite database, migrations, repositories
├── ForgeMediaMedia      — FFmpegProcessRunner, CompositeProcessingEngine, probing
├── ForgeMediaAI         — WhisperService, OllamaClient, LocalAgentRouter (opt-in)
├── ForgeMediaWorkers    — Background job executor, cancellation coordinator
├── ForgeMediaDiagnostics — Structured logs, audit trail
└── ForgeMediaCLI        — Terminal interface with TUI progress bars
```

Key constraints:
- Menu bar extra **never** runs media work — UI layer only
- Heavy jobs run in background tasks; UI receives progress events only
- AVFoundation first, FFmpeg second for codec paths
- GRDB `DatabaseQueue` + `ValueObservation` for reactive UI updates
- Chunked, resumable processing for long-form video (5-hour files supported)

---

## Job Lifecycle

`idle → preparing → running → taking longer → paused → completed → completed with warnings → failed → canceled → recovered`

Progress labels always name the current phase (e.g. "Transcribing segment 8 of 14…" not "Processing…").

---

## Privacy

| Feature | Status |
|---------|--------|
| Network calls | Blocked by default |
| Telemetry / analytics | Disabled |
| Remote crash reporting | Disabled |
| Cloud uploads | Disabled |
| Local AI (Whisper, Ollama) | Opt-in in Settings |
| Remote AI | Opt-in in Settings (disabled by default) |

---

## Troubleshooting

**App opens but shows no window**
- Fixed in v1.0: the app now uses `WindowGroup` + a notification bridge to guarantee window presentation on every launch, even after the user previously closed the window.

**CLI produces same-path output error**
- Fixed in v1.0: `defaultOutputURL` now strips all extensions and appends a preset suffix (e.g. `video_convert_h264.mp4`) so the output never collides with the input.

**FFmpeg not found**
```bash
brew install ffmpeg
```
ForgeMedia checks `/opt/homebrew/bin/ffmpeg`, `/usr/local/bin/ffmpeg`, and `/usr/bin/ffmpeg` automatically.

---

## Development

Run tests:
```bash
swift test
```

Interactive CLI:
```bash
./run_forgemedia.sh
```

See `docs/` for full architecture, design system, privacy contract, and agent mesh documentation.

---

## License

Local development build. Not for distribution.
