# ForgeMedia Local Agent Mesh and Self-Healing Pipeline

ForgeMedia should be built as a native macOS app first, then augmented by a local agent mesh that helps plan, inspect, test, and repair the system. The agent mesh must never become a replacement for deterministic Swift services, database transactions, or media-engine validation.

## Operating principle

Agents can propose plans, generate code, inspect logs, and suggest UI fixes. They should not directly run destructive media operations, mutate user media, or bypass user privacy choices. Every agent action that affects files, jobs, models, or settings must go through explicit tool definitions and audit logs.

## Agent roles

### 1. Core Developer Agent

Responsibilities:

- Read project architecture and design contracts.
- Implement Swift domain models, GRDB records, repositories, and migrations.
- Build service protocols for media, AI, archive, and agent orchestration.
- Add tests for pure domain logic and service boundaries.
- Keep UI views as state projections, not side-effect owners.

Primary outputs:

- Swift package modules.
- Xcode project/scheme.
- GRDB migrations.
- Service protocols and implementations.
- Unit/integration tests.

### 2. Design & Layout Agent

Responsibilities:

- Apply Apple-native layout, spacing, typography, material blur, and icon language.
- Review SwiftUI previews and HTML prototypes against ForgeMedia design docs.
- Translate Framer Motion principles into SwiftUI spring behavior without copying web UI directly.
- Ensure drag/drop targets feel fluid but remain accessible and reduced-motion safe.

Primary outputs:

- SwiftUI component specs.
- Motion token recommendations.
- Preview screenshots.
- UI mismatch reports.

### 3. Media/AI Engineering Agent

Responsibilities:

- Implement FFmpeg probe/progress parsing.
- Implement AVFoundation composer path.
- Integrate whisper.cpp wrapper and model metadata.
- Add optional Ollama/local model routing.
- Enforce resource budgets and fallback behavior.

Primary outputs:

- Media engine implementations.
- Model capability checks.
- Progress parsing.
- Quality check records.

### 4. Adversarial QA Agent

Responsibilities:

- Break the app intentionally.
- Fuzz file inputs, paths, permissions, cancellation, low disk, model failures, and menu-bar interactions.
- Force restarts during active jobs.
- Verify partial output recovery.
- Confirm privacy defaults remain intact.

Primary outputs:

- Failure reports.
- Repro steps.
- Required patches.
- Regression tests.

### 5. Vision/Layout Review Agent

Responsibilities:

- Capture screenshots or previews.
- Check for text overlap, panel stretching, clutter, unnatural animation, and poor contrast.
- Compare against Apple HIG and ForgeMedia design tokens.
- Flag reduced-motion regressions.

Primary outputs:

- Screenshot annotations.
- Layout mismatch bounding boxes.
- Motion/accessibility findings.

### 6. Release Engineer Agent

Responsibilities:

- Validate signing, sandbox, entitlements, notarization, and App Store constraints.
- Check third-party license attribution.
- Prepare privacy nutrition labels and support metadata.
- Build release artifacts.

Primary outputs:

- Release checklist.
- Entitlement report.
- License manifest.
- Distribution notes.

## Tool registry

The agent mesh should use MCP-style tools with explicit schemas:

| Tool | Allowed agents | Safety |
|---|---|---|
| `read_architecture` | All | Read-only |
| `read_design_contract` | All | Read-only |
| `generate_swift_patch` | Developer, Media/AI | Review required |
| `run_tests` | Developer, QA | Read/execute tests |
| `run_ui_preview` | Design, QA | Read/execute preview |
| `probe_media` | Media/AI, QA | User-selected files only |
| `run_media_job` | Media/AI | Explicit user confirmation |
| `cancel_job` | Developer, QA | Audit logged |
| `check_disk_space` | Developer, QA | Read-only |
| `inspect_job_logs` | QA, Vision | Bounded log window |
| `capture_preview` | Design, QA | Non-destructive |
| `update_grdb_schema` | Developer | Migration review required |
| `enable_remote_ai` | User only | Requires explicit opt-in |

## Self-healing loop

```text
1. User command or planned feature
2. Developer Agent drafts implementation
3. Design Agent reviews layout and motion
4. QA Agent runs adversarial tests
5. Vision Agent checks screenshots/previews
6. Issues are converted into concrete patches
7. Developer Agent applies fixes
8. Tests rerun
9. Release Engineer checks signing/licenses if shipping
10. Loop repeats until acceptance criteria pass
```

## Failure handling

Every failure must include:

- What failed.
- Where it failed.
- Repro steps.
- Expected behavior.
- Actual behavior.
- Logs or screenshots.
- Suggested patch.
- Regression test to add.

After three retries on the same failure, the system should stop auto-retrying and ask for human review.

## Graphify integration

Once the app target exists, runtime execution trees should be passed to Graphify to map:

- SwiftUI state → job queue updates.
- Job queue → worker execution.
- Worker execution → FFmpeg/AVFoundation/Whisper/Ollama calls.
- Media engine → progress events.
- Progress events → GRDB job events.
- GRDB observations → UI updates.
- QA failures → patch loop.

Use Graphify for:

- Architecture questions.
- Cross-module call-chain review.
- Failure root-cause mapping.
- Release impact analysis.

## Privacy gates

Agent actions must respect:

- No telemetry.
- No analytics.
- No remote media upload.
- No remote AI unless explicitly enabled.
- No automatic sharing of job history.
- Local logs must be user-controlled and exportable/deletable.

## Acceptance criteria for the agent mesh

- [ ] Agents cannot mutate user media without explicit confirmation.
- [ ] Remote AI remains disabled by default.
- [ ] Every tool call is auditable.
- [ ] QA can reproduce failures from logs and fixtures.
- [ ] Vision review can flag layout/motion regressions.
- [ ] Developer patches are scoped and test-backed.
- [ ] Graphify can trace UI → queue → worker → engine → UI loops.

## Immediate implementation path

1. Add this document to the project onboarding flow.
2. Add `docs/architecture.md` as the developer contract.
3. Add `docs/design-system.md` and `docs/interaction-feedback-states.md` as design contracts.
4. Create Swift modules and service protocols.
5. Add fake media engine for UI development.
6. Add real FFmpeg probe/progress parser.
7. Add adversarial fixtures.
8. Add Graphify runtime mapping after the first working app target exists.
