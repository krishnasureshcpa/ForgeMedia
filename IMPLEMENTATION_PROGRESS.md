# ForgeMedia Implementation — Live Progress

> Updated: 2026-06-19, mid-execution. Mirror of `.specify/constitution.md` + the build pipeline status. Restart from here if context is cleared.

## Goal

Build ForgeMedia per the approved plan: spec-kit 7-phase artifacts + 4-phase build pipeline. macOS 16 Tahoe, arm64, SwiftPM-only.

## Environment snapshot

- **Host:** macOS 26.4 (Tahoe), arm64, Swift 6.3 (swiftlang-6.3.0.123.5), target `arm64-apple-macosx26.0`
- **Toolchain:** CommandLineTools only — `xcodebuild` errors "requires Xcode" (confirmed). SwiftPM-only path is the only viable build.
- **Disk:** 7.3 GB free on `/System/Volumes/Data` (was 1.2 GB at start — user freed space). 7.6 GB free on `/`. Gates: ≥1.5 GB for build, ≥800 MB for DMG, ≥500 MB for screencapture.
- **Package.swift:** `swift-tools-version: 6.0`, `platforms: [.macOS(.v14)]`, GRDB 6.29.3 resolved.
- **Existing artifacts:** `~/Applications/ForgeMedia.app` (from prior build), `run_forgemedia.sh`, `ForgeMedia.app/` in repo root. Stale `ForgeMedia-v1.0.dmg` + `ForgeMedia.dmg` deleted.
- **Git:** "bad object HEAD" — repo has no commits. We won't commit anything in execution.
- **FFmpeg:** 8.1.1 at `/opt/homebrew/bin/ffmpeg`.
- **`specify` CLI:** not installed — spec-kit artifacts hand-written.
- **`graphify` CLI:** installed, standalone binary only (Python module not importable in system python3).
- **`rtk`:** not installed — global CLAUDE.md instruction cannot be honored. Bare commands used; deviation not written to `/Users/sgkrishna/CLAUDE.md`.

## Phase status

- [x] **Phase A — Disk preflight + cleanup.** Stale DMGs deleted, toolchain verified.
- [x] **Phase B-1 — `.specify/constitution.md`** written (9 principles, P1–P9, each citing source doc).
- [ ] **Phase B-2 — `.specify/specify.md`** (FR-/NFR-/CR- IDs, tech-agnostic).
- [ ] **Phase B-3 — `.specify/clarify.md`** (resolved questions table).
- [ ] **Phase B-4 — `.specify/plan.md`** (tech stack, build strategy, data model).
- [ ] **Phase B-5 — `.specify/tasks.md`** (30–40 tasks, 7 waves, [P] markers).
- [ ] **Phase B-6 — `.specify/analyze.md`** (cross-artifact consistency checks).
- [ ] **Phase C — SwiftPM build + bundle + Info.plist.** `swift package resolve`, `swift build -c release --product ForgeMediaApp`, hand-write `Sources/ForgeMediaApp/Info.plist`, write + run `scripts/bundle_app.sh`.
- [ ] **Phase C-2 — DMG + codesign.** `hdiutil create ... -format UDZO ForgeMedia.dmg`; `codesign --force --deep --sign -`.
- [ ] **Phase D — Launch + verify.** `open ~/Applications/ForgeMedia.app`, `pgrep -lf ForgeMediaApp`, `screencapture -x -t png ~/Desktop/forgemedia_launch.png`.

## Spec-kit artifact index (when written)

| File | Lines | Purpose | Source docs |
|---|---|---|---|
| `.specify/constitution.md` | ~120 | 9 governing principles | privacy-first.md, design-system.md, performance-quality.md, interaction-feedback-states.md, agent-orchestration.md |
| `.specify/specify.md` | ~80 | FR-/NFR-/CR- IDs | functionality-and-workflow.md, architecture.md, SOP.md, task_template.md |
| `.specify/clarify.md` | ~30 | Resolved ambiguities | decision-log this session |
| `.specify/plan.md` | ~150 | Tech stack, build, data model | Package.swift, docs/swift-architecture/ |
| `.specify/tasks.md` | ~200 | 30–40 dependency-ordered tasks | spec.md, plan.md |
| `.specify/analyze.md` | ~80 | Cross-artifact consistency | spec.md, plan.md, tasks.md, constitution.md |

## Build pipeline (exact commands, in order)

```bash
# Pre-gate
df -k ~  # ≥1.5 GB

# 1. Resolve + build
cd /Users/sgkrishna/MasterBase/ForgeMedia
swift package resolve
swift build -c release --product ForgeMediaApp

# 2. Hand-write Info.plist at Sources/ForgeMediaApp/Info.plist
#    (LSMinimumSystemVersion=16.0, LSUIElement=true, CFBundleIdentifier=com.localdev.forgemedia, etc.)

# 3. Create scripts/bundle_app.sh and run it
#    Assembles ~/Applications/ForgeMedia.app/Contents/{MacOS,Resources,Info.plist}

# Pre-gate
df -k ~  # ≥800 MB

# 4. DMG
hdiutil create -volname ForgeMedia -srcfolder ~/Applications/ForgeMedia.app \
  -ov -format UDZO ForgeMedia.dmg

# 5. Ad-hoc codesign
codesign --force --deep --sign - ~/Applications/ForgeMedia.app
codesign --verify --verbose=2 ~/Applications/ForgeMedia.app

# Pre-gate
df -k ~  # ≥500 MB

# 6. Launch + verify
open ~/Applications/ForgeMedia.app
sleep 2 && pgrep -lf ForgeMediaApp
screencapture -x -t png ~/Desktop/forgemedia_launch.png

# 7. Final report
df -k ~
```

## Known risks (live)

1. **Disk fills mid-pipeline** — `df -k` gates before SwiftPM build, DMG, screencapture. Fallback: prune `.build/`, `~/Library/Caches/`.
2. **`swift-tools 6.0` may reject `.macOS(.v16)`** — fallback to `.v14`, gate Tahoe features with `if #available(macOS 16, *)`. Note: SDK target is `arm64-apple-macosx26.0` so `.v16` may parse.
3. **`Sources/ForgeMediaWorkers/` missing** — only matters if a task references `ForgeMediaWorkers`. No spec-kit task does yet.
4. **Ad-hoc sign triggers Gatekeeper on relaunch** — fallback `xattr -dr com.apple.quarantine ~/Applications/ForgeMedia.app` or first-launch via right-click → Open.

## Constitution principles (P1–P9)

- **P1 Privacy-First** — no telemetry/analytics/cloud/remote-AI without explicit opt-in; default zero network calls
- **P2 Local-First Media** — AVFoundation first, FFmpeg second, Whisper local, CoreML/Metal as optimization
- **P3 Chunked Resumable Jobs** — 5h video MUST NOT load into RAM; segment plan + checkpoints
- **P4 Quality Gates** — checksum, duration, codec, bitrate, audio layout, subtitle status, engine version per job
- **P5 Concurrency Discipline** — MenuBarExtra never runs media; 1 export unless opted-in
- **P6 Calm Design** — #f5f5f7 canvas, #0066cc accent sparse, no neon, reduced-motion respected, state coverage mandatory
- **P7 Trustworthy Progress** — phase > percent; confidence labels; 60s indeterminate timeout; retry 0/2/4/8s
- **P8 Agent Mesh Boundaries** — agents propose, never mutate user media; audit log required
- **P9 Platform & Build** — macOS 16 Tahoe arm64 only; SwiftPM-only; no xcodebuild; no universal binaries

## User decisions (locked)

- macOS minimum: 16 Tahoe
- Build path: hybrid → collapsed to SwiftPM-only (no Xcode available)
- Disk cleanup: user does it manually; plan enumerates what to free
- Permissions: keep on (every Bash call prompts interactively)
- `rtk`: bare commands; global CLAUDE.md not modified

## If context clears, resume from here

Re-read this file, then:
1. Finish remaining `.specify/` artifacts in order: specify.md, clarify.md, plan.md, tasks.md, analyze.md.
2. Run the build pipeline section above.
3. Update the Phase status checklist.
4. Report final `df -k ~` and screenshot path.