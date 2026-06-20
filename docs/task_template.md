# ForgeMedia Task Template

Task ID: `[TASK_ID]_[TASK_NAME]`

## Description

Provide a clear, concise description of what this task accomplishes and why it is needed. Include context about how it fits into the larger ForgeMedia app.

Reference inputs:

- Open Design Apple design system: `/Users/sgkrishna/MasterBase/design/open-design/design-systems/apple/DESIGN.md`
- Apple first-principles skill: `/Users/sgkrishna/MasterBase/design/Apple-Native-OS-Design/apple-design-first-principle/SKILL.md`
- Open Design craft rules: `/Users/sgkrishna/MasterBase/design/open-design/craft/`
- ShiftMedia premium redesign notes: `/Users/sgkrishna/MasterBase/ShiftMedia-V1/instructions-ShiftMedia-premium-redesign.pdf`
- Performance and quality target: `docs/performance-quality.md`.
- Privacy-first policy: `docs/privacy-first.md`.
- Project architecture plan: `docs/architecture.md` when present.

## Dependencies

- Depends On: `[List task IDs this depends on, or “None”]`
- Blocks: `[List task IDs that depend on this task, or “None”]`

## Acceptance Criteria

- [ ] Functional behavior is implemented behind a stable protocol or service boundary.
- [ ] Error handling covers missing inputs, invalid files, process failures, cancellation, and low-resource states where relevant.
- [ ] Edge cases are covered by unit or integration tests.
- [ ] UI changes use Apple-native spacing, typography, materials, and restrained motion.
- [ ] Motion is purposeful, interruptible where appropriate, and respects reduced motion.
- [ ] Visual design avoids a dark base and avoids using color as the main background; use neutral surfaces, material layers, subtle borders, and purposeful accent signals instead.
- [ ] Any useful ShiftMedia premium redesign guidance is adapted for ForgeMedia without copying old-build assumptions.
- [ ] Privacy-first defaults are preserved: no telemetry, no analytics, no cloud uploads, no remote AI unless explicitly enabled.
- [ ] Optional on-device history is user-controlled, clearly labeled, and easy to disable/delete.
- [ ] Code includes clear, concise comments only where they explain non-obvious logic.
- [ ] Existing comments and code are preserved unless behavior changes require an update.
- [ ] Tests run from the ForgeMedia project root or the relevant Swift package target.
- [ ] Xcode project/scheme builds with `xcodebuildmcp` when available.
- [ ] No secrets, credentials, or local absolute paths are committed.
- [ ] Documentation is updated when behavior, configuration, or architecture changes.

## Implementation Plan

1. Read and confirm scope
   - Read the related architecture/design docs.
   - Confirm whether the task is UI, domain, data, media engine, AI orchestration, or QA.
   - Keep the implementation footprint small.

2. Add or update domain contracts
   - Add models, protocols, or enums before concrete implementations.
   - Prefer value types for immutable domain data.
   - Keep side effects out of domain models.

3. Implement the smallest working slice
   - Add code near the existing module it belongs to.
   - Use dependency injection for external services.
   - Avoid broad refactors unless they are required for correctness.

4. Wire UI or service integration
   - UI should use SwiftUI primitives and system materials.
   - Background work must not block the menu bar UI.
   - Long-running operations should report progress and support cancellation.

5. Add tests
   - Unit tests for pure logic.
   - Integration tests for database, process wrappers, API clients, and file operations.
   - UI tests or previews for visible behavior.

6. Verify
   - Run focused tests first.
   - Run the relevant Swift package test target.
   - Build with `xcodebuildmcp` when available.
   - Inspect changed files for accidental broad edits.

## Testing Checklist

- [ ] Unit tests cover success path.
- [ ] Unit tests cover invalid input.
- [ ] Unit tests cover empty/missing state.
- [ ] Integration tests cover persistence or external process behavior.
- [ ] Cancellation path is tested or explicitly marked not applicable.
- [ ] Error messages are user-safe and actionable.
- [ ] UI state is tested in light and dark appearances when visual behavior changes.
- [ ] Accessibility labels and keyboard behavior are checked for UI changes.
- [ ] Performance impact is acceptable for menu bar responsiveness.
- [ ] Reduced-motion behavior is checked for animation changes.
- [ ] No regression in existing tests.

## Code References

- `Sources/ForgeMediaDomain/...` — Domain models, protocols, and pure business logic.
- `Sources/ForgeMediaData/...` — GRDB records, migrations, and persistence services.
- `Sources/ForgeMediaMedia/...` — AVFoundation, FFmpeg, Whisper, and media helpers.
- `Sources/ForgeMediaAI/...` — Ollama, MCP-style tools, routing, and local agent orchestration.
- `Sources/ForgeMediaUI/...` — SwiftUI views, components, and motion tokens.
- `Sources/ForgeMediaDiagnostics/...` — logging, crash recovery, QA, and telemetry.
- `Tests/...` — Unit, integration, and UI tests.

## Implementation Notes

### Architecture Decisions

- [Decision Point]: [Rationale and chosen approach]
- [Trade-off]: [What was considered and why this path was chosen]

### Configuration Details

```swift
// Include example configuration with explanatory comments.
// Keep secrets out of committed files.
```

### Integration Points

- [How this task integrates with existing systems]
- [APIs or interfaces that need to be considered]
- [Data flow and dependencies]

## Risk Assessment

- [Risk Type]: [Description and mitigation strategy]
- Technical Debt: [Any shortcuts taken and plan to address]
- Performance Impact: [Expected impact and optimization opportunities]

## Review Checklist

- [ ] Code follows Swift naming and module boundaries.
- [ ] Comments explain why, not what.
- [ ] Documentation is complete and accurate.
- [ ] Tests provide adequate coverage.
- [ ] Security, privacy, and sandbox boundaries are respected.
- [ ] No telemetry/analytics code paths are introduced by default.
- [ ] Performance benchmarks or responsiveness checks are met.
- [ ] Accessibility standards are maintained.
- [ ] Open Design craft rules were considered.
- [ ] Apple first-principles checks were applied: intuition, friction, kinematics, invisible craftsmanship.

## Open Questions

- [Questions that need answers before or during implementation]
- [Design decisions that need stakeholder input]
- [Technical clarifications needed]

## Future Considerations

- [Potential enhancements or optimizations]
- [Scalability considerations]
- [Maintenance requirements]
- [Technical debt to be addressed later]

## Resources and References

- Open Design README: `/Users/sgkrishna/MasterBase/design/open-design/README.md`
- Open Design AGENTS: `/Users/sgkrishna/MasterBase/design/open-design/AGENTS.md`
- Open Design CLAUDE: `/Users/sgkrishna/MasterBase/design/open-design/CLAUDE.md`
- Apple design system: `/Users/sgkrishna/MasterBase/design/open-design/design-systems/apple/DESIGN.md`
- Apple tokens: `/Users/sgkrishna/MasterBase/design/open-design/design-systems/apple/tokens.css`
- Apple component reference: `/Users/sgkrishna/MasterBase/design/open-design/design-systems/apple/components.html`
- Apple first principles: `/Users/sgkrishna/MasterBase/design/Apple-Native-OS-Design/apple-design-first-principle/SKILL.md`
- Privacy-first policy: `docs/privacy-first.md`
- Context7 docs: GRDB.swift, SwiftUI, Ollama API, XcodeBuildMCP.
