# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

ForgeMedia is a privacy-first, offline-native macOS media command center for long-form creators, archivists, and studios. The current repository contains planning documents, design contracts, and a protocol-first Swift scaffold; it does not yet contain a buildable Xcode project or Swift Package Manager target.

Core promise: **Your media stays on your Mac. No telemetry. No analytics. No cloud uploads by default.**

## Repository layout

| Path | Purpose |
|------|---------|
| `docs/architecture.md` | Module breakdown, data layer, media/AI engines, privacy gates, self-healing agent mesh |
| `docs/design-system.md` | Apple-native visual language: neutral surfaces, ForgeMedia tokens, motion rules, component specs |
| `docs/interaction-feedback-states.md` | 10 job lifecycle states and progress feedback rules |
| `docs/privacy-first.md` | Default privacy posture and user-facing copy constraints |
| `docs/performance-quality.md` | 5-hour video targets, chunked processing, quality gates |
| `docs/agent-orchestration.md` | 6-agent mesh roles, MCP tool registry, self-healing loop |
| `docs/task_template.md` | Template for implementation tasks with acceptance criteria and review checklists |
| `docs/swift-architecture/ForgeMediaArchitecture.swift` | Protocol-first scaffold: models, protocols, GRDB migrations |
| `docs/prototypes/forge-media-progress-prototype.html` | Interactive HTML prototype of job states |
| `research/research-system-ForgeMedia.txt` | Architectural ledger with persona research, hardware mapping, rationale |
| `session-ForgeMedia/session-1-ForgeMedia.md` | Full session-1 transcript |

## High-level architecture

ForgeMedia ships as a native macOS app with explicit separation between UI and heavy media work:

```text
ForgeMedia App
├── ForgeMediaApp / ForgeMediaUI   — SwiftUI MenuBarExtra, main window, job cards, settings
├── ForgeMediaDomain               — Job models, presets, privacy policy, pure validation logic
├── ForgeMediaData                 — GRDB SQLite database, migrations, repositories, ValueObservation
├── ForgeMediaMedia                — MediaProbeService, FFmpegProcessRunner, AVFoundationComposer, ArchiveService
├── ForgeMediaAI                   — WhisperService, OllamaClient, LocalAgentRouter, MCPToolRegistry
├── ForgeMediaWorkers              — Background worker / XPC helper, job executor, cancellation coordinator
└── ForgeMediaDiagnostics          — Structured logs, audit trail, crash-local diagnostics, license manifest
```

Key architectural boundaries:

- The **MenuBarExtra must never run media work**; it only displays state and sends commands to the worker layer.
- Heavy jobs run in background workers or an XPC helper; the UI receives progress events, cancellation state, and final results only.
- Use **AVFoundation first, FFmpeg second**: native Apple paths for same-container stitching; FFmpeg for containers, filters, subtitles, burn-in, legacy formats.
- Use **GRDB.swift** with `DatabaseQueue` for persistence; stream UI updates via `ValueObservation`.
- Process long videos in **resumable segments with checkpoints**; never load a five-hour video fully into memory.
- Local AI is opt-in and gated by explicit privacy settings; remote AI is disabled by default.

### Job lifecycle states

All UI surfaces must handle: idle → preparing → running → taking longer → paused → completed → completed with warnings → failed → canceled → recovered. Progress copy must name the current phase (e.g., "Transcribing segment 8 of 14…") rather than generic placeholders.

## Development commands

The repository is in planning/scaffold phase; there is no app target yet. Planned commands once the Swift project exists:
- Build: `xcodebuildmcp build` or `swift build`
- Test: `xcodebuildmcp test` or `swift test`
- Single test: `swift test --filter <TestName>`

Until the project target exists, the primary workflow is reading and updating docs and the scaffold in `docs/`. The HTML prototype can be opened directly in a browser.

## Design and product constraints (non-negotiable)

- **No dark base.** Visual foundation is `#f5f5f7` light neutral. Color is for state and affordance, not decoration.
- **Privacy On by default.** No telemetry, analytics, cloud uploads, remote crash reports, or remote AI unless explicitly enabled.
- **Menu bar stays responsive.** Media work is architecturally prohibited from running on the UI thread.
- **Five-hour video must not crash.** Chunked, resumable, checkpointed processing is mandatory.
- **Output quality must be validated.** Record checksums, duration, resolution, codec, bitrate, audio layout, and subtitle status per job.
- **ANE is a fallback, not a promise.** Core ML acceleration is an optimization with explicit fallback to CPU/Metal.
- **One accent per surface.** Use `#0066cc` sparingly: one primary action per panel, one progress signal per job.
- **Reduced motion must be respected.** Remove translate/scale/rotate animations when reduced motion is preferred.

## Agent mesh (6 roles)

1. Core Developer Agent — Swift models, GRDB schema, services, tests
2. Design & Layout Agent — Apple-native layout, materials, motion tokens
3. Media/AI Engineering Agent — FFmpeg, AVFoundation, Whisper, Ollama integration
4. Adversarial QA Agent — fuzzing files, paths, cancellation, low disk, restart recovery
5. Vision/Layout Review Agent — screenshots, overlap, contrast, reduced-motion regressions
6. Release Engineer Agent — signing, sandbox, entitlements, licenses, distribution

Agents must not mutate user media or bypass privacy settings. Destructive actions require explicit user confirmation and audit logging.

## External design references

- Open Design Apple system: `/Users/sgkrishna/MasterBase/design/open-design/design-systems/apple/DESIGN.md`
- Apple tokens: `/Users/sgkrishna/MasterBase/design/open-design/design-systems/apple/tokens.css`
- Open Design craft rules: `/Users/sgkrishna/MasterBase/design/open-design/craft/`
- Apple first-principles: `/Users/sgkrishna/MasterBase/design/Apple-Native-OS-Design/apple-design-first-principle/SKILL.md`
- Legacy reference: `/Users/sgkrishna/MasterBase/ShiftMedia-V1/instructions-ShiftMedia-premium-redesign.pdf`