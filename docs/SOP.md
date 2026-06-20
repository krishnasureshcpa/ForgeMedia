# ForgeMedia — Standard Operating Procedure

> Version 1.0 · 2026-06-14 · macOS 27 Golden Gate Target

---

## 1. Repository Hygiene

### Before Starting Any Task
```bash
cd ~/MasterBase/ForgeMedia
git status                    # Confirm clean working tree
swift build                   # Verify baseline builds
```

### Branch Strategy
```
main                          # Always deployable, protected
├── feature/<name>            # Feature branches off main
├── fix/<name>                # Bug fixes
└── release/<version>         # Release stabilization
```

### Commit Convention
```
<type>(<scope>): <description>

Types: feat, fix, refactor, test, docs, design, chore
Scope: domain, data, media, ai, ui, app, diagnostics, docs
Example: feat(domain): add QualityCheck model and protocol
```

---

## 2. Design-to-Code Pipeline

### Step 1 — Design Contract Review
Before writing Swift, confirm the visual direction in HTML prototypes:
- Open `docs/prototypes/forge-media-v2.html` in a browser
- Validate against `docs/design-system.md` tokens
- Check all 11 job lifecycle states render correctly
- Verify light mode AND dark mode (use system toggle)
- Run anti-slop checklist from Open Design craft rules

### Step 2 — Protocol-First Implementation
1. Define or update the protocol/interface in `Sources/ForgeMediaDomain/`
2. Add any new models as value types (structs) with `Sendable` conformance
3. Update GRDB migrations in `Sources/ForgeMediaData/DatabaseService.swift`
4. Implement the protocol behind the existing boundary
5. Wire into `AppModel` via dependency injection

### Step 3 — UI Projection
1. UI views in `Sources/ForgeMediaUI/` or `Sources/ForgeMediaApp/`
2. Views are pure state projections — no side effects
3. All states covered: loading, empty, error, populated, edge
4. Use `ForgeMediaTokens` for all colors, radii, motion durations
5. SwiftUI previews for interactive design review

### Step 4 — Verification
```bash
swift build                  # Must pass with 0 errors
swift test                   # All tests must pass (requires Xcode)
```
- Run adversarial tests from `docs/architecture.md` fixture list
- Verify Privacy On is never violated
- Verify MenuBarExtra never blocks during long jobs

---

## 3. Module Boundaries (DO NOT VIOLATE)

```
ForgeMediaDomain       ← ZERO dependencies. Everything depends on this.
ForgeMediaDiagnostics  ← Domain only. Logger is actor-isolated.
ForgeMediaData         ← Domain + GRDB. Sync API (DatabaseQueue).
ForgeMediaMedia        ← Domain + Diagnostics. ProcessingEngine impls.
ForgeMediaAI           ← Domain. Agent routing + model clients.
ForgeMediaUI           ← Domain. Shared components + design tokens.
ForgeMediaApp          ← ALL modules. @main entry. MenuBarExtra + Window.
```

### Rules
- **Domain never imports anything.** No GRDB, no SwiftUI, no Foundation beyond basics.
- **UI never runs media work.** Views read state; workers process media.
- **Data layer is synchronous.** `DatabaseQueue` — single-user local app.
- **Actors for shared mutable state.** `DiagnosticsLogger`, `OllamaClient` are actors.
- **Protocols for engine boundaries.** `ProcessingEngine`, `TranscriptEngine`, `LocalAgentRouter`.

---

## 4. Adding a New Feature (End-to-End)

### Example: Adding "Quality Check" to job outputs

| Step | File(s) | Action |
|------|---------|--------|
| 1 | `Sources/ForgeMediaDomain/QualityCheck.swift` | Define `QualityCheck` struct + `QualityCheckResult` enum |
| 2 | `Sources/ForgeMediaDomain/JobOutput.swift` | Add `qualityChecks: [QualityCheck]` field |
| 3 | `Sources/ForgeMediaDomain/ProcessingEngine.swift` | Add `qualityCheck` to protocol if new engine behavior |
| 4 | `Sources/ForgeMediaData/DatabaseService.swift` | Add migration for `quality_checks` table |
| 5 | `Sources/ForgeMediaData/GRDBRecords.swift` | Add `QualityCheck` FetchableRecord conformance |
| 6 | `Sources/ForgeMediaData/QualityCheckRepository.swift` | CRUD repository |
| 7 | `Sources/ForgeMediaMedia/FakeProcessingEngine.swift` | Emit mock quality checks |
| 8 | `Sources/ForgeMediaUI/QualityCheckBadge.swift` | UI component |
| 9 | `Sources/ForgeMediaUI/JobCardView.swift` | Integrate badge |
| 10 | `Tests/ForgeMediaDomainTests/` | Unit tests for model |
| 11 | `Tests/ForgeMediaDataTests/` | Integration tests for repo |

---

## 5. Testing Protocol

### Unit Tests (Domain)
- All pure logic: model validation, enum behavior, computed properties
- Run: `swift test --filter ForgeMediaDomainTests`

### Integration Tests (Data, Media, AI)
- Database migrations, repository CRUD, engine contracts
- Run: `swift test --filter ForgeMediaDataTests`

### Adversarial Tests (Pre-release gate)
- Zero-byte files, unsupported formats, cancel during encode
- Low disk simulation, corrupt SQLite, missing models
- Menu bar clicks during active render
- Privacy defaults remain intact

---

## 6. Release Checklist

- [ ] `swift build` passes (0 errors, 0 warnings)
- [ ] All tests pass
- [ ] Adversarial test suite passes
- [ ] Design review against `docs/design-system.md`
- [ ] Privacy audit: no network calls in default mode
- [ ] Third-party licenses documented (FFmpeg, Whisper.cpp, GRDB, ZIPFoundation)
- [ ] Hardened Runtime + Sandbox enabled
- [ ] Entitlements: user-selected files, localhost network only
- [ ] Notarization successful
- [ ] App icon + menu bar icons present
- [ ] Privacy nutrition labels prepared

---

## 7. Quick Reference

| Action | Command |
|--------|---------|
| Build | `swift build` |
| Test (all) | `swift test` |
| Test (single) | `swift test --filter <TestSuite>` |
| Clean build | `swift package clean && swift build` |
| Update deps | `swift package update` |
| Open prototype | `open docs/prototypes/forge-media-v2.html` |
| View module graph | `swift package show-dependencies` |

---

## 8. Design Reference Stack

| Resource | Path / URL |
|----------|-----------|
| ForgeMedia design tokens | `docs/design-system.md` |
| Interaction states | `docs/interaction-feedback-states.md` |
| Architecture blueprint | `docs/architecture.md` |
| Privacy policy | `docs/privacy-first.md` |
| Performance targets | `docs/performance-quality.md` |
| Agent orchestration | `docs/agent-orchestration.md` |
| Task template | `docs/task_template.md` |
| HTML prototype (v2) | `docs/prototypes/forge-media-v2.html` |
| Swift scaffold | `docs/swift-architecture/ForgeMediaArchitecture.swift` |
| Apple HIG | `https://developer.apple.com/design/human-interface-guidelines` |
| macOS 27 UI Kit (Sketch) | `https://www.sketch.com/s/57153a31-3379-4737-8ac6-dbfd6525f052` |
| Apple Design Resources | `https://developer.apple.com/design/resources/` |
| Open Design (Apple) | `~/MasterBase/design/open-design/design-systems/apple/` |
| macOS design skill | `~/MasterBase/design/macos-design-skill/` |
| Animation discipline | `~/MasterBase/design/open-design/craft/animation-discipline.md` |
| Anti-slop rules | `~/MasterBase/design/open-design/craft/anti-ai-slop.md` |