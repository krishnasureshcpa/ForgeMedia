# ForgeMedia — Functionality & Workflow Catalog

> Complete capability inventory mapped to user workflows · macOS 27 · v1.0

---

## 1. Core Capability Map

### A. Media Intake
| Capability | Input | Behavior | States |
|---|---|---|---|
| **File Drop** | Drag video/audio/image onto drop zone | Validates file, probes metadata, enqueues job | Drop zone: idle, targeted, processing |
| **Folder Drop** | Drag folder onto drop zone | Recursively scans for media, batches into job list | Same as file + batch count indicator |
| **Open Dialog** | ⌘O or File > Open | Native NSOpenPanel with media type filter | — |
| **Paste from Clipboard** | ⌘V with media in clipboard | Detects media type, creates job | — |
| **Watch Folder** | User-designated folder | Polls for new files, auto-enqueues | Active monitoring indicator |

### B. Media Probing
| Capability | Engine | Output |
|---|---|---|
| **Metadata Extraction** | FFmpeg probe / AVFoundation | Duration, resolution, codec, bitrate, audio layout, rotation, HDR metadata |
| **Stream Analysis** | FFmpeg | Video streams, audio streams, subtitle tracks, chapter markers |
| **Quality Assessment** | Custom | Detect: zero-byte, corrupt stream, unsupported codec, variable framerate |
| **Output Estimation** | Calculated | Estimated output file size based on preset + input properties |

### C. Processing Engines
| Engine | What It Does | Presets |
|---|---|---|
| **AVFoundation Composer** | Native timeline: merge, trim, stitch, export | convert_h264, convert_hevc, stitch, merge_audio |
| **FFmpeg Runner** | Container wrapping, filters, subtitles, legacy formats, burn-in | convert_legacy, burn_subtitles, extract_audio |
| **Whisper.cpp** | Local transcription with CPU/Metal/CoreML | transcribe (SRT, VTT, JSON) |
| **Archive Service** | ZIP/TAR extraction, safe path validation | extract, preview |
| **Quality Validator** | Post-process: duration match, audio sync, checksum, codec verification | validate_output |

### D. Job Management
| Capability | Action | Behavior |
|---|---|---|
| **Enqueue** | Add media + preset → job queue | Creates JobRecord, persists to SQLite, starts processing |
| **Pause** | User pauses running job | Saves checkpoint, suspends child process, preserves partial output |
| **Resume** | User resumes paused job | Reads checkpoint, resumes from last safe segment |
| **Cancel** | User cancels job | Sends SIGTERM to child process, cleans temp files, records event |
| **Retry** | After failure | Re-enqueues with same parameters, clears error state |
| **Delete** | Remove job from history | Deletes JobRecord + events, prompts if output exists |
| **Reorder** | Drag to reorder queue | Updates priority, running job unaffected |
| **Batch Actions** | Select multiple → pause/cancel/delete | Confirmation dialog, bulk state transition |

### E. Progress & Feedback
| Capability | Surface | Content |
|---|---|---|
| **Compact Progress** | MenuBarExtra panel | Phase badge, mini progress ring, job name, cancel button |
| **Job Card** | Main window queue | Phase, progress bar, progress label, confidence, elapsed time, actions |
| **Processing Sheet** | Detail panel (⌘I) | Step-by-step log, engine output, expandable diagnostics |
| **Notifications** | macOS Notification Center | Job completed, job failed, taking longer than expected |
| **Dock Badge** | App Dock icon | Active job count badge |

### F. Output Handling
| Capability | Behavior |
|---|---|
| **Open Output** | Reveals file in Finder, or opens with default app |
| **Share** | Native NSSharingService (AirDrop, Mail, Messages) |
| **Export Preset** | Save job configuration as reusable preset |
| **Output History** | Browse completed jobs with filters: date, preset, status |
| **Quality Report** | Per-job record: input/output checksums, duration match, codec verification |

### G. Privacy & Security
| Capability | Behavior |
|---|---|
| **Privacy On (default)** | No network, no telemetry, no analytics, local-only processing |
| **Privacy Mode Toggle** | Settings: Privacy On → Local AI Only → Remote AI Opt-In |
| **Local History** | Opt-in job history in user-controlled app support directory |
| **Data Export/Delete** | One-click export or delete of all local data |
| **Privacy Prompts** | Explicit copy before any network or AI handoff ("This action sends transcript text to Ollama on this Mac") |

### H. Local AI (Opt-in)
| Capability | Engine | Behavior |
|---|---|---|
| **Natural Language Job Creation** | Ollama / llama.cpp | "Transcribe all videos in ~/Movies/Interviews to SRT" |
| **Batch Planning** | Ollama | Suggests preset + segment strategy for large folders |
| **Quality Analysis** | Ollama | Reviews job logs, suggests fixes for failed jobs |
| **Model Selection** | Ollama API | List local models, select by capability/speed |
| **Agent Budget** | Token/time gates | Prevents runaway GPU usage during media processing |

### I. Presets & Configuration
| Capability | Behavior |
|---|---|
| **Built-in Presets** | Transcribe, Convert H.264, Convert HEVC, Stitch, Merge Audio |
| **Custom Presets** | User-created from any job configuration |
| **Import/Export** | Share presets as JSON files |
| **Default Preset** | Set per-file-type default |

---

## 2. User Workflows

### Workflow A: Creator Exporting a Video
```
1. User drags "final_cut_4k.mov" onto ForgeMedia window
2. App probes → shows: 4K, HEVC, 24min, 5.1 audio
3. User selects "Convert H.264" preset
4. Job card appears: "Preparing…" → "Exporting segment 3 of 8…" → "Verifying output…"
5. Menu bar shows compact progress ring at 62%
6. Job completes → notification: "final_cut_4k.mp4 saved"
7. User clicks "Open Output" → Finder reveals file
8. Quality check: duration matches, audio layout verified, checksum stored
```

### Workflow B: Podcaster Transcribing an Interview
```
1. User drops "episode_42.wav" (2.5 hours)
2. Selects "Transcribe" preset (Whisper, SRT output, English)
3. App splits into 14 segments, transcribes sequentially
4. Progress: "Transcribing segment 8 of 14…" with measured confidence
5. Transcript saved as "episode_42.srt" in same folder
6. Optional: User enables local Ollama to summarize transcript
7. Ollama generates chapter markers and show notes
```

### Workflow C: Archivist Processing Old Footage
```
1. User drops folder "Family_Videos_1998" containing 47 .avi files
2. App scans recursively, creates batch of 47 jobs
3. User selects "Convert H.264" with "Preserve original date" option
4. Batch processes sequentially with progress per file
5. Failed job on file 23: "Codec not supported" → suggests FFmpeg engine
6. All other 46 files complete successfully
7. Quality report: 46/47 succeeded, 1 failed → detailed diagnostics
```

### Workflow D: Privacy-Conscious User
```
1. Privacy On by default — green pill visible in toolbar
2. User drops sensitive legal deposition video
3. App confirms: "Privacy On: this job stays on your Mac"
4. Transcription runs entirely offline via Whisper.cpp
5. No network calls made — verifiable in Settings > Diagnostics
6. Output saved locally, no cloud sync, no telemetry
```

### Workflow E: Recovery After Crash
```
1. User was exporting a 3-hour video when Mac rebooted
2. On relaunch, ForgeMedia detects unfinished job
3. Shows "Recovered" card: "Export was at segment 9 of 14 — resume or discard?"
4. User clicks "Resume" → continues from checkpoint
5. Partial output preserved, no re-processing of completed segments
```

---

## 3. State Machine: Job Lifecycle

```
                    ┌──────────────────────────────────────┐
                    │              IDLE / READY             │
                    │   Media loaded, waiting for action    │
                    └──────────┬───────────────────────────┘
                               │ User clicks "Start" / auto-start
                               ▼
                    ┌──────────────────────────────────────┐
                    │             PREPARING                │
                    │   Probing, estimating, building plan │
                    └──────────┬───────────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    ▼                     ▼
         ┌──────────────┐      ┌──────────────────┐
         │    FAILED     │      │     RUNNING      │◄────────┐
         │  Cannot start │      │  Segments 1..N   │         │
         └──────────────┘      └──┬───────┬───────┘         │
                                  │       │                  │
                    ┌─────────────┘       └─────────┐        │
                    ▼                                ▼        │
         ┌──────────────┐                  ┌──────────────┐  │
         │   CANCELED   │                  │    PAUSED    │──┘
         │  User stopped│                  │ User/System  │ Resume
         └──────────────┘                  └──────────────┘
                                                   │
                    ┌──────────────────────────────┘
                    ▼
         ┌──────────────────┐
         │    VALIDATING     │
         │  Quality checks   │
         └──────┬───────────┘
                │
     ┌──────────┼──────────┐
     ▼          ▼          ▼
┌─────────┐ ┌─────────┐ ┌──────────┐
│COMPLETED│ │WARNINGS │ │  FAILED  │
│   ✓     │ │  ⚠ + ✓  │ │    ✕     │
└─────────┘ └─────────┘ └──────────┘

RECOVERY: App relaunch → detects unfinished job → RECOVERED state
          → Resume from last checkpoint or Discard
```

---

## 4. Architecture: Data Flow

```
USER ACTION (drag file, select preset)
         │
         ▼
┌─────────────────┐
│   AppModel      │  @MainActor, @Observable
│  (UI State)     │  Receives user intent
└────────┬────────┘
         │ Creates JobRecord, persists to SQLite
         ▼
┌─────────────────┐
│  JobRepository  │  GRDB ValueObservation
│  (Data Layer)   │  Streams changes back to UI ──────────┐
└────────┬────────┘                                        │
         │ Dispatches to engine                            │
         ▼                                                 │
┌─────────────────┐                                        │
│ ProcessingEngine│  Protocol boundary                     │
│ (Media Worker)  │  FakeProcessingEngine / FFmpegRunner   │
└────────┬────────┘                                        │
         │ Emits JobProgress via callback                  │
         ▼                                                 │
┌─────────────────┐                                        │
│  Diagnostics    │  Actor-isolated logger                 │
│  Logger         │  Ring buffer + os.Logger               │
└────────┬────────┘                                        │
         │ Progress events written to SQLite               │
         ▼                                                 │
    JobRepository ─── ValueObservation ────► AppModel ◄────┘
         │                                        │
         │                                        ▼
         │                                SwiftUI Views
         │                                (JobCardView,
         │                                 MenuBarView,
         │                                 MainWindow)
         │
    ┌────┴────┐
    │ SQLite  │  GRDB DatabaseQueue
    │ (Local) │  Jobs, Events, Presets, Settings
    └─────────┘
```

---

## 5. Privacy Enforcement Points

| Checkpoint | Rule |
|---|---|
| App launch | No analytics SDKs initialized |
| Network request | Gated behind `PrivacySettings.canUseRemoteAI` |
| File access | Sandboxed — user-selected files only |
| Crash reports | Stored locally only (unless user opts in) |
| AI processing | Privacy prompt before any model handoff |
| Data export | User-initiated only, with destination confirmation |
| Log storage | `~/Library/Application Support/ForgeMedia/` — user-controllable |

---

## 6. Accessibility Coverage

| Requirement | Implementation |
|---|---|
| VoiceOver labels | All interactive elements have `.accessibilityLabel()` |
| Progress announcements | `accessibilityValue` with phase + percentage |
| Keyboard navigation | Full keyboard control: Tab, Space, Enter, Escape |
| Reduced motion | `prefersReducedMotion` → disable spring/scale animations |
| Dynamic Type | SF Pro supports system text size adjustments |
| High contrast | Respect system contrast settings |
| Focus rings | Visible focus indicators on all interactive elements |