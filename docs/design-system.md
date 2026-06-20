# ForgeMedia Design System

ForgeMedia is a privacy-first local media processing app for creators who work with sensitive, long-form footage. The product language should feel calm, capable, and transparent: the UI should make heavy work legible without making the user feel watched, rushed, or overwhelmed.

This design contract adapts the open design resources already referenced by the ForgeMedia task template:

- Open Design Apple design system: `/Users/sgkrishna/MasterBase/design/open-design/design-systems/apple/DESIGN.md`
- Apple tokens: `/Users/sgkrishna/MasterBase/design/open-design/design-systems/apple/tokens.css`
- Apple component reference: `/Users/sgkrishna/MasterBase/design/open-design/design-systems/apple/components.html`
- Open Design craft rules: `/Users/sgkrishna/MasterBase/design/open-design/craft/`
- Framer design system as a motion reference only: `/Users/sgkrishna/MasterBase/design/open-design/design-systems/framer/DESIGN.md`
- ForgeMedia performance target: `docs/performance-quality.md`
- ForgeMedia privacy policy: `docs/privacy-first.md`

## Product personality

ForgeMedia should feel like a professional media workstation with a quiet interface:

- **Private by default**: no telemetry, no cloud-first language, no analytics phrasing.
- **Local-first**: emphasize that media stays on the Mac unless the user explicitly enables a remote/local AI service.
- **Precise but humane**: show what is happening, how much remains, and what can be recovered; avoid vague progress or technical dumping.
- **Premium without theatricality**: use material, spacing, type, and restrained motion instead of dark neon chrome or decorative gradients.
- **Long-job aware**: every state must survive a five-hour media job without making the user stare at a spinner.

## Visual direction

ForgeMedia should borrow Apple's calm editorial structure, but avoid turning into an Apple clone. The interface should use neutral surfaces, material layers, subtle borders, and purposeful accent signals.

### Color roles

Use Apple's neutral ladder as the base, with a ForgeMedia accent that signals action without becoming the product identity.

| Role | Token | Value | Use |
|---|---|---:|---|
| Background | `--fm-bg` | `#f5f5f7` | Main app background |
| Surface | `--fm-surface` | `#ffffff` | Cards, sheets, panels |
| Surface raised | `--fm-surface-raised` | `#fbfbfd` | Hovered or elevated panels |
| Text primary | `--fm-fg` | `#1d1d1f` | Main copy |
| Text secondary | `--fm-fg-2` | `#424245` | Helper copy |
| Text muted | `--fm-muted` | `#6e6e73` | Metadata |
| Border soft | `--fm-border-soft` | `#e8e8ed` | Subtle dividers |
| Border | `--fm-border` | `#d2d2d7` | Inputs, cards |
| Accent | `--fm-accent` | `#0066cc` | Primary actions and focus |
| Accent strong | `--fm-accent-strong` | `#0077ed` | Hover / active progress |
| Success | `--fm-success` | `#1f8f55` | Completed checks |
| Warning | `--fm-warning` | `#b7791f` | Space, compatibility, or quality warnings |
| Danger | `--fm-danger` | `#c43b3b` | Destructive or failed actions |

Rules:

- Do not use dark neon backgrounds as the main ForgeMedia canvas.
- Do not use purple/blue/cyan gradients as the default brand language.
- Use color for state and affordance, not decoration.
- Keep accent usage sparse: one primary action per panel, one progress signal per job.

### Typography

Use Apple-like system typography unless the app has an approved custom font stack.

| Role | Token | Value |
|---|---|---|
| Display | `--fm-font-display` | `-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", sans-serif` |
| Body | `--fm-font-body` | `-apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif` |
| Mono | `--fm-font-mono` | `"SF Mono", ui-monospace, Menlo, Monaco, Consolas, monospace` |

Principles:

- Headlines should be short, confident, and task-oriented.
- Body copy should explain media state in plain language.
- Technical metadata belongs in compact, aligned rows, not paragraphs.
- Avoid invented quality claims such as "Hollywood-grade" or "perfect."

### Spacing and layout

ForgeMedia is a productivity app; density should be controlled by task context.

| Context | Spacing behavior |
|---|---|
| Menu bar menu | Compact, readable, no decorative illustration |
| Job card | Enough breathing room to scan state, duration, destination, and controls |
| Processing detail sheet | Dense metadata allowed, but grouped by phase |
| Empty / onboarding panels | More whitespace and one clear primary action |
| Long media jobs | Prioritize scannability over visual drama |

Default radii:

- `8px` for compact controls
- `12px` for cards and input fields
- `18px` for large panels or modal sheets
- `999px` only for pill badges and primary buttons

## Motion language

Motion should explain state changes, not advertise the product.

Use the Open Design animation discipline rules:

- Motion earns its place when the user is moving through space, time, or state.
- Micro-feedback should be around `150ms`.
- Entering panels should be around `200–300ms`.
- Cross-screen transitions should be around `300–500ms`.
- Non-navigation microinteractions should stay under `500ms`.
- Repeated motion must be pausable or finite.
- Respect `prefers-reduced-motion: reduce`.

### Approved motion patterns

| Pattern | Use | Duration | Notes |
|---|---|---:|---|
| Button press compression | Confirm tap/click | `80–120ms` | Tiny scale change; no bounce |
| Panel entry | Sheet, drawer, popover | `220ms` | Ease-out, opacity + vertical movement |
| Progress fill | Determinate media progress | `150–300ms` | Smooth, never flashing |
| Stage reveal | Show next processing phase | `180–250ms` | Only when phase actually changes |
| Success check | Completed validation | `180ms` | One-shot, no looping sparkle |
| Error shake | Critical invalid input | `180–220ms` | Use sparingly; pair with text |

### Avoid

- Endless spinners for media jobs.
- Decorative looping gradients.
- Motion as the only indication of state.
- Progress bars that imply false precision.
- Skeleton shimmer that continues after content is available.
- Framer-style black void as ForgeMedia's main surface. Framer can inspire compact, product-forward motion, but not the visual base.

## Component language

### Primary button

Use for the next irreversible or highest-value action in a panel.

- Fill: `--fm-accent`
- Text: white
- Radius: `999px`
- Hover: `--fm-accent-strong`
- Active: subtle scale `0.98`
- Loading state: inline progress indicator plus label change, e.g. "Preparing…"

### Secondary button

Use for safe alternatives.

- Transparent or surface background
- Border: `--fm-border`
- Text: `--fm-fg`
- Hover: `--fm-surface-raised`

### Job card

A job card must make the current state obvious without opening details.

Required visible information:

- Job name or media title
- Current phase
- Progress state: unknown, estimated, determinate, validating, completing, failed, canceled
- Destination
- Duration or estimated remaining time when reliable
- Primary action: pause, cancel, retry, open output, inspect issue

### Progress indicator

Choose the indicator by expected duration and confidence:

| Duration / confidence | Indicator |
|---|---|
| 0–300ms | No indicator |
| 300ms–2s | Subtle spinner or skeleton |
| 2–10s | Matched skeleton or labeled spinner |
| 10–30s | Determinate progress with phase label |
| 30–60s | Progress with cancel and current phase |
| 60s+ | Progress with cancel, last update time, and "taking longer than expected" fallback |

Progress copy should be specific:

- "Reading video stream…"
- "Splitting into 14 segments…"
- "Transcribing segment 8 of 14…"
- "Checking audio sync…"
- "Writing output to Movies/ForgeMedia…"

Avoid:

- "Working…"
- "Almost done…"
- "Processing your file…"
- "Hollywood-grade enhancement running…"

### Privacy banner

Use only when a feature changes the privacy posture.

Recommended copy:

- "Privacy On: this job stays on your Mac."
- "Remote AI is off for this feature."
- "This action will send a transcript to the selected endpoint. Review before continuing."

Do not use vague language like:

- "We may use data to improve services."
- "Cloud processing may occur."
- "Anonymous analytics."

## State coverage

Every user-facing surface that fetches, transforms, or accepts data must include these states:

1. **Loading**: what is being prepared, plus a 15s "taking longer than expected" fallback.
2. **Empty**: headline, explanation, and one primary action.
3. **Error**: what happened, why if known, and what the user can do.
4. **Populated**: the normal case.
5. **Edge**: long filenames, missing metadata, very large files, partial outputs, RTL text, and unavailable disk space.

For media jobs, add:

6. **Running**: current phase, progress source, cancel/pause availability, and last update time.
7. **Paused**: reason, resumed-from point, and resume action.
8. **Canceled**: what was cleaned up and what can be recovered.
9. **Recovered**: partial output found, validation status, and retry/resume options.

## Accessibility

- Every progress change must have a static label, not just animation.
- Use `role="status"` for non-urgent progress updates.
- Use `role="alert"` for errors that block the job.
- Do not move focus to spinners.
- Move focus to loaded content when a user-initiated action completes.
- Toasts must be pauseable on hover/focus if they auto-dismiss.
- Reduced motion must remove translate/scale/rotate animation and keep opacity/color transitions only when needed.

## Implementation guidance

When implementing SwiftUI views:

- Prefer `Material` surfaces and system shapes.
- Use `PhaseAnimator` or explicit state-driven transitions for small, meaningful state changes.
- Use `ProgressView` only when paired with a text label and phase name.
- Keep long-running media work out of the UI thread and menu bar path.
- Throttle UI progress updates to avoid churn.
- Store job state in domain models; keep UI views as state projections.

When implementing HTML prototypes or design artifacts:

- Use the Apple token block as the base unless ForgeMedia-specific tokens are intentionally defined.
- Keep accent usage to at most two visible accent roles per screen.
- Use `data-od-id` on major sections if the artifact will be reviewed with Open Design tooling.
- Avoid external placeholder image CDNs; use honest labeled placeholders when media previews are unavailable.

## Design review checklist

Before calling a ForgeMedia UI pass complete:

- [ ] The UI preserves Privacy On by default.
- [ ] Heavy media work is visibly separated from the UI path.
- [ ] Long jobs have progress, cancellation, recovery, and last-update information.
- [ ] Motion is purposeful, finite, and reduced-motion safe.
- [ ] The app avoids dark neon chrome and generic AI gradients.
- [ ] Progress copy explains the current phase, not vague effort.
- [ ] Empty and error states offer a clear next action.
- [ ] The design remains usable in menu bar, window, and mobile-sized layouts.
- [ ] No unsupported quality claims are present.
