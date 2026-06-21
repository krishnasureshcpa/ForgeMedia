# ForgeMedia

Privacy-first, offline-native macOS media command center for long-form creators, archivists, and studios.

**Your media stays on your Mac. No telemetry. No analytics. No cloud uploads by default.**

![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/license-local--dev-lightgrey)
![Build](https://img.shields.io/badge/build-passing-brightgreen)

---

## What it is

ForgeMedia is a native macOS application that batch-converts, transcribes, and archives video files entirely on-device. It combines a warm retro-OS interface (think a sun-faded manual meets a CRT terminal at night) with the density and precision of professional media tools like Final Cut Pro or Logic Pro.

Every job runs locally. No subscription. No internet required.

---

## Features

| Feature | Details |
|---------|---------|
| **Drag & drop queue** | Drop files or folders onto the window; sub-folders mirror into output with configurable suffix |
| **Live activity stream** | Dark CRT-style terminal pane streams every backend event in real time |
| **10-state job lifecycle** | idle → preparing → running → taking longer → paused → completed → warnings → failed → canceled → recovered |
| **Named progress phases** | "Encoding segment 3 of 6…" — never a generic spinner |
| **Configurable output naming** | Folder suffix and file suffix independently editable (default `_ForgeMedia`) |
| **FFmpeg-powered** | Homebrew FFmpeg for conversion; AVFoundation for native same-container paths |
| **Privacy On by default** | Zero network calls, no crash reporters, no remote AI unless you explicitly enable it |
| **Menu bar status item** | Monitor active jobs without switching windows |
| **CLI tool (`fm`)** | Scriptable batch processing from the terminal |
| **Open-dubbing pipeline** | Dub + translate to English via open-source models (opt-in) |

---

## Interface

The UI follows the **Nostalgia design system** — a retro macOS desktop-OS aesthetic:

- **Menu-bar strip** — 36 px warm cream/taupe surface with job counters and privacy badge
- **Job cards** — every job is a "window" with a 32 px title bar (filenames in monospace), phase badge, and a 4 px brand-orange progress bar flush at the bottom
- **Activity stream** — fixed 360 px dark pane (`#2B1B11`) with orange timestamps and colored phase labels, like a real terminal log
- **Folder intake** — dashed 1 px border drop zone; goes solid orange on drag-over
- **Settings** — tabbed preferences with espresso active tabs and Nostalgia-style rows

Color palette: toasted cream `#FFEEDD` · espresso `#381C00` · glowing orange `#FF631A` · taupe border `#8D6C5D`.

---

## Requirements

- macOS 14 or later (Apple Silicon recommended; Intel supported)
- [FFmpeg](https://ffmpeg.org/download.html) via Homebrew: `brew install ffmpeg`
- Swift 6.0+ (Xcode Command Line Tools or full Xcode)

---

## Installation

### Download the app

The prebuilt `ForgeMedia.app` and `ForgeMedia.dmg` are included in the repository root. Double-click `ForgeMedia.dmg`, then drag `ForgeMedia.app` to `~/Applications` or `/Applications`.

```bash
# Or from the terminal:
open ForgeMedia.dmg
```

### Install to ~/Applications from source

```bash
git clone https://github.com/krishnasureshcpa/ForgeMedia.git
cd ForgeMedia
swift build -c release --product ForgeMediaApp
bash scripts/ship_release.sh        # bundles .app, signs, mirrors, builds .dmg
cp -R ForgeMedia.app ~/Applications/
open ~/Applications/ForgeMedia.app
```

`ship_release.sh` is idempotent — re-run it any time to pick up source changes.

---

## Quick Start

### GUI app

1. **Open** `ForgeMedia.app` (double-click the app or the DMG)
2. **Drop** video files or a folder onto the drop zone, or use **Select Video / Select Folder** in the toolbar
3. **Choose a preset** from the dropdown (Convert H.264, Convert HEVC, Transcribe…)
4. Watch the **Activity Stream** on the right for live progress; click the folder icon on any green completed card to reveal the output file in Finder

Closing the window keeps the app alive in the menu bar. Click the `film` icon in the menu bar to reopen.

### Command Line (`fm`)

Build the CLI:

```bash
swift build --product ForgeMediaCLI
cp .build/arm64-apple-macosx/debug/ForgeMediaCLI ~/.local/bin/fm
```

Usage:

```bash
fm video.mp4                               # convert to H.264 (default)
fm video.mp4 --preset convert_hevc         # convert to H.265
fm video.mp4 --preset transcribe           # extract transcript
fm /path/to/videos --recursive             # batch convert a folder
```

---

## Output Naming

ForgeMedia mirrors your source folder hierarchy into a parallel output tree with configurable suffixes.

**Example** — source folder `Celebration_Videos/` with suffix `_ForgeMedia`:

```
Celebration_Videos/
  Morning Buffet.mp4          →  Celebration_Videos_ForgeMedia/Morning Buffet_ForgeMedia.mp4
  Walking-Vlogs/
    clip01.mp4                →  Celebration_Videos_ForgeMedia/Walking-Vlogs_ForgeMedia/clip01_ForgeMedia.mp4
```

Change the folder suffix and file suffix independently in **Settings → General → Output Naming**. Set either field blank to disable that suffix.

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
├── ForgeMediaUI         — Shared views: JobCardView, ActivityStreamView, DesignTokens
├── ForgeMediaDomain     — Job models, presets, protocols, privacy policy
├── ForgeMediaData       — GRDB SQLite database, migrations, repositories
├── ForgeMediaMedia      — FFmpegProcessRunner, CompositeProcessingEngine, OutputNaming
├── ForgeMediaAI         — WhisperService, OllamaClient, LocalAgentRouter (opt-in)
├── ForgeMediaDiagnostics — Structured logs, audit trail
└── ForgeMediaCLI        — Terminal interface with TUI progress bars
```

Key constraints:
- Menu bar extra **never** runs media work — UI layer only
- Heavy jobs run in background tasks; UI receives progress events only
- AVFoundation first, FFmpeg second for codec paths
- GRDB `DatabaseQueue` + `ValueObservation` for reactive UI updates
- Chunked, resumable processing for long-form video (5-hour files supported)
- All output paths resolved through `OutputNaming.resolveOutputURL(for:preset:)` — reads `folderSuffix`/`fileSuffix` from `UserDefaults` and mirrors sub-folder hierarchy

---

## Job Lifecycle

```
idle → preparing → running → taking longer → paused →
completed → completed with warnings → failed → canceled → recovered
```

Progress labels always name the current phase ("Transcribing segment 8 of 14…" not "Processing…").

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

## Building from Source

```bash
git clone https://github.com/krishnasureshcpa/ForgeMedia.git
cd ForgeMedia
swift package resolve

# Debug build (fast iteration)
swift build --product ForgeMediaApp

# Release build + full app bundle + DMG
swift build -c release --product ForgeMediaApp
bash scripts/ship_release.sh
```

Run tests:

```bash
swift test
```

---

## Troubleshooting

**App opens but shows no window**
The app uses `WindowGroup` + a notification bridge to guarantee window presentation on every launch, even after a previous close. Try clicking the menu bar `film` icon → **Open ForgeMedia**.

**FFmpeg not found**
```bash
brew install ffmpeg
```
ForgeMedia checks `/opt/homebrew/bin/ffmpeg`, `/usr/local/bin/ffmpeg`, and `/usr/bin/ffmpeg` automatically. You can also set a custom path in **Settings → Engine**.

**Output file collides with source**
Set a non-empty file suffix in **Settings → General → Output Naming** (default `_ForgeMedia`). This suffix is appended before the extension so output never overwrites the source.

**Folder icon on completed job does nothing**
Requires the output file to actually exist on disk (real FFmpeg run, not a fake/demo job). The folder icon calls `NSWorkspace.activateFileViewerSelecting` to open Finder with the file selected.

---

## Changelog

### v1.1.0 (2026-06-21)
- **Nostalgia design system** — complete UI redesign: warm toasted-cream canvas, espresso ink, glowing orange accent, 1 px taupe borders, 3 px radius, dark CRT terminal activity stream
- **Window metaphor job cards** — each job renders as a macOS window with a 32 px title bar, window control dots, and a 4 px flush progress bar
- **Configurable output naming** — separate folder suffix and file suffix settings; sub-folder hierarchy mirrored into output tree
- **Folder reveal** — clicking the folder icon on a completed job opens Finder with the output file selected (`NSWorkspace.activateFileViewerSelecting`)
- **Physical button press** — all buttons shift 1 px down on `:active` (flat retro key feel)

### v1.0.0
- Initial release: FFmpeg pipeline, 10-state job lifecycle, menu bar extra, GRDB persistence, language detection sheet

---

## License

Local development build. Not for distribution.
