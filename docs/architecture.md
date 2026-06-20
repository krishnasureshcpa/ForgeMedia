# ForgeMedia macOS Architecture Blueprint

This blueprint turns the ForgeMedia requirements into a realistic, offline-first macOS app architecture. The current folder only contains design/operations docs, so this file should become the source of truth before creating the Swift app target.

## 1. Product slice

### MVP

- Native macOS app shell using SwiftUI + AppKit integration where needed.
- `MenuBarExtra` status item with compact job state, pause/cancel/open actions, and privacy status.
- Main window with drag/drop media intake, job queue, processing detail panel, presets, and output history.
- GRDB-backed SQLite job queue with idempotent jobs, checkpoints, audit logs, and recovery.
- FFmpeg wrapper for probing, transcoding, stitching, subtitle burn-in, and container edge cases.
- AVFoundation path for native timeline operations where it is the best fit.
- whisper.cpp transcription with local model selection and optional Core ML/Metal acceleration when available.
- Privacy-first defaults: no telemetry, no analytics, no remote media upload, no remote AI unless explicitly enabled.
- Progress feedback states documented in `docs/interaction-feedback-states.md`.

### v1

- Optional local Ollama/llama.cpp agent orchestration for planning, batch folder sweeps, and natural-language job creation.
- MCP tool hub for local media tools, file operations, and job orchestration.
- Archive engine using Libarchive or ZIPFoundation.
- Local preset sync/export/import.
- Objective quality checks where practical: duration mismatch, audio sync sanity, loudness, subtitle timing, checksum, codec/resolution/bitrate metadata.
- Crash/restart recovery with partial output resume.

### Later

- Core ML / Metal Performance Shaders pipelines for super-resolution, dubbing, or lip-sync models after licensing, quality, and benchmark gates.
- App Store distribution path if the bundled engines/licenses and entitlements allow it.
- Advanced color/HDR workflows only after licensed tooling and validation support the claims.

## 2. Recommended architecture

```text
ForgeMedia App
├── ForgeMediaApp / ForgeMediaUI
│   ├── SwiftUI MenuBarExtra shell
│   ├── Main window
│   ├── Job cards and progress views
│   ├── Drag/drop intake
│   └── Settings / privacy / presets
│
├── ForgeMediaDomain
│   ├── Job models
│   ├── Processing phases
│   ├── Preset models
│   ├── Privacy policy
│   └── Pure validation logic
│
├── ForgeMediaData
│   ├── GRDB SQLite database
│   ├── Migrations
│   ├── Job queue repository
│   ├── Preset repository
│   └── ValueObservation publishers
│
├── ForgeMediaMedia
│   ├── MediaProbeService
│   ├── FFmpegProcessRunner
│   ├── AVFoundationComposer
│   ├── ArchiveService
│   └── ProgressParser
│
├── ForgeMediaAI
│   ├── WhisperService
│   ├── OllamaClient
│   ├── LocalAgentRouter
│   ├── MCPToolRegistry
│   └── ModelBudgetPolicy
│
├── ForgeMediaWorkers
│   ├── Background worker process / XPC helper boundary
│   ├── Job executor
│   ├── Cancellation coordinator
│   └── Recovery checkpoint writer
│
└── ForgeMediaDiagnostics
    ├── Structured logs
    ├── Audit trail
    ├── Crash-local diagnostics
    └── License attribution manifest
```

### Important boundary

The menu bar UI must never run media work. It should only display state and send high-level commands to the worker/orchestrator layer.

## 3. Native shell

### SwiftUI `MenuBarExtra`

Responsibilities:

- Show current job phase and progress.
- Show Privacy On/off status.
- Provide pause, cancel, open output, and open main window actions.
- Stay responsive during long jobs.

Avoid:

- Heavy logging in the menu.
- Blocking calls.
- Direct `Process` execution from menu-bar views.
- Modal sheets that trap the user while a job is running.

### Main window

Use Apple-native layout patterns:

- Top bar for global actions, search, view mode, settings.
- Sidebar only if there are 3+ destinations; otherwise keep a single-purpose utility layout.
- Center area for media intake and job queue.
- Right-side detail sheet for active job diagnostics.
- Drag/drop as a first-class input path.
- Empty state with one clear primary action.

### AppKit integration

Use AppKit for:

- File coordination and security-scoped bookmarks.
- Advanced drag/drop behavior.
- Window drag zones and traffic-light integration.
- Native panels, alerts, and menus.
- Vibrancy/material surfaces where SwiftUI primitives are insufficient.

## 4. Data and job queue

Use GRDB.swift with SQLite for:

- Job queue.
- Processing history.
- Presets.
- Media metadata cache.
- Agent prompt/job-plan history if local AI is enabled.
- Audit logs.
- Output validation records.

Recommended tables:

- `jobs`
- `job_events`
- `job_checkpoints`
- `job_outputs`
- `media_assets`
- `presets`
- `privacy_settings`
- `agent_runs`
- `mcp_tool_registry`
- `quality_checks`

GRDB pattern:

- Use `DatabaseQueue` for a single-user local app.
- Use migrations for schema changes.
- Use `ValueObservation` to stream job queue changes to SwiftUI.
- Keep UI views as projections of domain models.
- Keep side effects out of domain models.

Example GRDB observation pattern:

```swift
let observation = ValueObservation.tracking { db in
    try JobRecord.fetchAll(db, order: [{ \.$createdAt, .descending }])
}

for try await jobs in observation.values(in: databaseQueue) {
    // Update SwiftUI state on the main actor if needed.
}
```

## 5. Media processing engine

### FFmpeg

Use FFmpeg for:

- Probing.
- Container wrapping.
- Legacy formats.
- Subtitles.
- Burn-in.
- Filters.
- Edge cases AVFoundation does not handle cleanly.

Implementation requirements:

- Run via `Process` in a background worker, not the UI.
- Parse progress from stderr.
- Support cancellation.
- Stream logs into a bounded ring buffer.
- Write structured job events to GRDB.
- Preserve partial outputs where safe.
- Verify output duration, codec, audio layout, and checksum.

Static FFmpeg bundling:

- Treat bundled FFmpeg as a release-engineering item, not a code detail.
- Track FFmpeg version, build flags, codecs, and licenses.
- Document third-party licenses in the app.
- Prefer hardened, reproducible builds for release.

### AVFoundation

Use AVFoundation for:

- Native timeline composition.
- Fast Apple Silicon media paths.
- Merging compatible tracks.
- Basic trimming/stitching.
- Asset export where it avoids FFmpeg overhead.

Use FFmpeg when:

- Container/format support is broader.
- Filters/subtitles/burn-in are needed.
- Objective metadata checks require exact codec details.

### Archive engine

Use Libarchive or ZIPFoundation for:

- ZIP/TAR extraction.
- Multi-threaded folder sweeps.
- Safe extraction previews.
- Output packaging.

Rules:

- Never extract outside the user-selected destination.
- Validate paths to avoid zip-slip traversal.
- Preserve user permission prompts and sandbox boundaries.

## 6. AI and local model layer

### Whisper.cpp transcription

Whisper.cpp supports Apple Silicon acceleration through ARM NEON, Accelerate, Metal, and optional Core ML. Core ML can route encoder inference through ANE on supported devices, but the app must treat ANE as an optimization path with fallback, not a guaranteed behavior.

Implementation requirements:

- Embed or locate whisper.cpp binaries/models safely.
- Store model metadata: name, quantization, source, license, Core ML build status.
- Support CPU, Metal, and Core ML modes.
- Fall back gracefully when Core ML/ANE compilation or execution fails.
- Cache transcripts by input checksum + model + preset.
- Output SRT/VTT/JSON transcript formats.

Do not claim:

- "Perfect transcription."
- "ANE always used."
- "Zero memory footprint."

Say:

- "Local transcription with hardware acceleration when available."
- "Core ML/ANE acceleration attempted; fallback used if unavailable."

### Upscaling / restoration

Use Core ML / Metal / MPS pipelines only after:

- Model license is compatible.
- Model is converted to `.mlpackage` or another supported format.
- Quality benchmarks exist.
- Resource budget is enforced.
- The UI clearly communicates limitations.

Avoid unsupported claims:

- "Dolby Vision certified."
- "Hollywood-grade."
- "Perfect restoration."

Use safer positioning:

- "Local upscaling preset."
- "Quality checks completed."
- "HDR metadata preserved when supported by the source and preset."

### Dubbing / lip sync

Treat dubbing and lip sync as later-phase capabilities:

- Require consent and licensing checks for voices/person likeness.
- Use local TTS engines only with compatible model licenses.
- Keep generated media clearly labeled when synthetic.
- Do not bypass DRM or licensing restrictions.

## 7. Local agent orchestration

### Local model provider

Use Ollama or llama.cpp as the local model runtime. Ollama exposes an OpenAI-compatible endpoint at `http://localhost:11434/v1/`, which can be used by a Swift client without shipping remote credentials.

Agent routing should consider:

- GPU busy state.
- CPU load.
- Memory pressure.
- Battery/power mode.
- Active media job priority.
- Token/time budget.
- User privacy settings.

### MCP tool hub

MCP should expose local tools as versioned capabilities:

- Probe media.
- Create job plan.
- Run FFmpeg job.
- Run AVFoundation job.
- Transcribe with Whisper.
- Check disk space.
- Validate output.
- Archive/extract folder.
- Summarize diagnostics.

Rules:

- Tool definitions are versioned.
- Tool execution is audited.
- Destructive tools require explicit confirmation.
- Remote tools are disabled unless the user opts in.
- The agent cannot directly mutate the database except through domain services.

## 8. Privacy and security

ForgeMedia default posture:

- Privacy On.
- No telemetry.
- No analytics.
- No cloud upload.
- No remote AI by default.
- Local logs stored in user-controlled app support directories.
- Optional local history is user-controlled and easy to delete.
- Sensitive media never leaves the Mac without explicit confirmation.

Privacy prompts must say exactly what will be sent:

Good:

- "This action sends the transcript text to the selected local Ollama model on this Mac."
- "Remote AI is off. This job will run locally."

Avoid:

- "We may use data to improve services."
- "Anonymous analytics."
- "Cloud processing may occur."

## 9. Apple-native design system

ForgeMedia should use Apple HIG-inspired restraint:

- System materials: `.regularMaterial`, `.ultraThinMaterial`, `.thinMaterial`.
- System typography and SF Symbols-style monoline icons.
- Dynamic system layout anchors instead of hardcoded offsets.
- Clear empty, loading, error, running, paused, recovered, and completed states.
- Fluid spring motion for drag/drop and state transitions.
- Reduced-motion support.

Motion policy:

- Press feedback: `0.08–0.16s`.
- Panel enter: `0.20–0.35s`.
- Drag morph: spring `response: 0.35`, `dampingFraction: 0.86`.
- Progress fill: smooth, no flashing.
- No decorative looping gradients.
- No motion as the only signal of state.

Drag/drop target behavior:

- Expand/breathe subtly on drag-over.
- Use continuous corner radius.
- Show file count and estimated action.
- Keep the target usable if the user cancels drag.

## 10. Self-healing verification loop

The user requested a multi-agent mesh. Implement it as a project workflow first, then automate it once the app target exists.

Agents:

1. **Core Developer Agent**
   - Builds Swift models, GRDB schema, media services, and core views.
2. **Design & Layout Agent**
   - Applies Apple-native layout, material blur, fluid spring constants, and negative space.
3. **Adversarial QA Agent**
   - Fuzzes files, paths, cancellation, low disk, model failure, menu-bar clicks, and restart recovery.
4. **Vision/Layout Review Agent**
   - Captures screenshots/previews and checks for overlap, clutter, unnatural stretching, and reduced-motion issues.
5. **Release Engineer**
   - Validates signing, sandbox, entitlements, licenses, and distribution metadata.

Self-healing loop:

```text
User command
  → Core Developer Agent proposes implementation
  → Design Agent reviews UI/motion
  → QA Agent attacks edge cases
  → Vision Agent checks frames
  → Issues are filed as concrete patches
  → Developer Agent fixes
  → Tests rerun
  → Repeat until release gate passes
```

## 11. Verification checklist

Before claiming the app is bulletproof:

- [ ] Menu bar remains responsive during a long FFmpeg job.
- [ ] App restart recovers jobs and partial outputs.
- [ ] Cancellation stops child processes and cleans safely.
- [ ] Low disk space is detected before and during jobs.
- [ ] Zero-byte and unreadable files fail with actionable copy.
- [ ] Drag/drop rejects unsupported files gracefully.
- [ ] Progress labels name the current phase.
- [ ] Indeterminate progress has a timeout.
- [ ] Privacy prompts are explicit before remote/local AI handoff.
- [ ] Reduced motion removes transform/scale/rotate animations.
- [ ] VoiceOver labels describe job state and actions.
- [ ] FFmpeg/Whisper/model licenses are documented.
- [ ] Signing, sandbox, and entitlements match distribution path.

## 12. Immediate next steps

1. Create the Swift package/Xcode app target with modules listed above.
2. Add GRDB migrations and `JobRecord` models.
3. Build a fake `ProcessingEngine` first so UI can be developed without real media.
4. Add FFmpeg probe/progress parser behind `MediaEngine` protocol.
5. Add AVFoundation composer path for compatible merge/trim jobs.
6. Add whisper.cpp wrapper with CPU-only MVP, then optional Core ML/Metal.
7. Add Ollama client behind `LocalAgentRouter` with privacy gate.
8. Add adversarial test fixtures: zero-byte file, missing output path, low disk simulation, canceled process, corrupt transcript cache.
9. Add SwiftUI previews for menu bar panel, job card states, drag/drop target, and processing detail sheet.
10. Run design review against `docs/design-system.md` and `docs/interaction-feedback-states.md`.

## Source notes

- GRDB.swift docs confirm `ValueObservation` can stream database changes into Swift concurrency, Combine, or RxSwift.
- Ollama docs confirm an OpenAI-compatible local API at `http://localhost:11434/v1/`.
- whisper.cpp search results indicate Apple Silicon support through ARM NEON, Accelerate, Metal, and optional Core ML. Core ML can use ANE on supported devices, but fallback behavior must be implemented.
