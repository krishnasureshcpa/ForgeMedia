# ForgeMedia — OpenDesign macOS Design Brief

> **Instructions for any AI designer using the OpenDesign macOS system:**  
> Read this file top to bottom before opening any component or generating any pixel.  
> This file answers every question the OpenDesign `apple` design-system and craft library would ask.  
> After reading, load `tokens.css` from the Apple design-system into your artifact `<style>` block
> and reference `components.manifest.json` before inventing a new control.

---

## 0. How to Use This Brief

```
Load order for the design agent:
1. This file (CLAUDE_DESIGN_ZIP_FILE.md) — full product and design contract
2. /MasterBase/design/open-design/design-systems/apple/tokens.css — token root
3. /MasterBase/design/open-design/design-systems/apple/DESIGN.md — visual language
4. /MasterBase/design/open-design/design-systems/apple/components.manifest.json — component inventory
5. /MasterBase/design/Apple-Native-OS-Design/apple-design-first-principle/SKILL.md — Apple-first principles
6. /MasterBase/ForgeMedia/Sources/ForgeMediaUI/DesignTokens.swift — ForgeMedia token overrides
```

Apply Apple-first principles from the SKILL.md. Override nothing in `tokens.css` unless this brief
explicitly gives you a ForgeMedia token override.

---

## 1. System Philosophy & Hardware-Aligned Architecture

### What is ForgeMedia?

ForgeMedia is a **privacy-first, offline-native macOS media command center** for long-form creators
(documentary filmmakers, podcast editors, archivists, studios). It converts, transcribes, dubs, and
stitches video entirely on-device using FFmpeg, Core ML, and Whisper — zero cloud uploads, zero
analytics, zero telemetry unless the user opts in.

### Target User Persona

- **Primary:** Pro creator on Apple Silicon Mac (M3/M4 Pro/Max). Handles 1–5 hour source files.
  Has 10–200 videos to process. Wants to fire and forget a batch job while editing in Final Cut.
- **Secondary:** Studio archivist. Ingests legacy formats into modern H.265 vaults.
- **Tertiary:** Privacy-conscious developer or journalist who cannot send footage to cloud services.

### Emotional Vector

The app should feel like a **studio-grade machine**: confident, calm, industrial.
Not playful. Not minimalist to the point of emptiness. Every control should feel *placed with purpose*.
The job queue is a production console, not a to-do list.

### Hardware-Aligned Architecture Questions & Answers

**Q: How does the app map to Apple Silicon asymmetric cores?**  
A: Media encoding (FFmpeg) runs on Performance cores via background tasks. The menu bar status item,
job card animations, and progress streaming run only on Efficiency cores via Publisher → SwiftUI.
The UI never touches the media stack.

**Q: How does the app handle thermal pressure?**  
A: Jobs are serialized by default (one running at a time). The user can set up to 4 concurrent jobs
in Settings. Each FFmpeg process is isolated; cancellation sends SIGINT then SIGTERM.

**Q: What is the activation policy?**  
A: `NSApplicationActivationPolicyRegular` — shows Dock icon. Not LSUIElement.
When the main window is closed, the app persists in the menu bar.

---

## 2. Visual Mastery — Design Token Contract

### 2.1 Palette Override (ForgeMedia → Apple tokens)

ForgeMedia uses the Apple token palette with specific overrides. Map them before designing.

| ForgeMedia Role | Token / Hex | Apple token | Notes |
|---|---|---|---|
| `Colors.bg` | `#f5f5f7` | `--surface-primary` | Window background, light neutral |
| `Colors.fg` | `#1d1d1f` | `--text-primary` | Primary text |
| `Colors.fgSecondary` | `#424245` | `--text-secondary` | Secondary labels |
| `Colors.muted` | `#6e6e73` | `--text-tertiary` | Hint text, captions |
| `Colors.accent` | `#0066cc` | `--accent` | **ONE** primary action per panel |
| `Colors.accentStrong` | `#0077ed` | `--accent-hover` | Hover state only |
| `Colors.success` | `#1a8c5c` | `--semantic-success` | Completed, verified |
| `Colors.warning` | `#b7791f` | `--semantic-warning` | Paused, slower than expected |
| `Colors.danger` | `#d43b3b` | `--semantic-error` | Failed, canceled |
| `Colors.border` | `rgba(0,0,0,0.08)` | `--border-default` | Card outlines |
| `Colors.borderSoft` | `rgba(232,232,237,0.6)` | `--border-subtle` | Inner separators |

**Anti-slop rule:** Never use raw indigo (`#6366f1`, `#4f46e5`). The only blue is `#0066cc` /
`#0077ed`. One visible use of `--accent` per screen region — not 6+.

### 2.2 Glass Material System

This is a Mac app. Use NSVisualEffectView materials — not border + drop-shadow cards.

| ForgeMedia context | SwiftUI material | When |
|---|---|---|
| `Glass.base` | `.ultraThinMaterial` | Window background tint |
| `Glass.surface` | `.thinMaterial` | Job cards, default panels |
| `Glass.elevated` | `.regularMaterial` | Hovered cards, drag targets |
| `Glass.floating` | `.thickMaterial` | Modals, popovers, context menus |

**No dark base.** App background is always `Colors.bg` (`#f5f5f7`). Black/dark sections are
forbidden except for the activity stream timeline ticks (muted).

### 2.3 Typography

Use SF Pro — it is the system font on macOS. Do not specify `Inter`, `Roboto`, or any custom font.

| Role | Size | Weight | Tracking | Usage |
|---|---|---|---|---|
| App title bar | 15pt | `.semibold` | default | "ForgeMedia" in top bar |
| Job title | 14pt | `.medium` | default | Filename in job card |
| Phase label | 12pt | `.regular` | default | "Encoding segment 5 of 8…" |
| Caption / badge | 10pt | `.medium` | +0.02em | Privacy badge, keyboard hints |
| Activity stream | 11pt | `.regular` | default | Event messages |
| Settings section | 13pt | `.regular` | default | Form labels |

**Reduced motion:** All `translate / scale / rotate` animations must be disabled when
`@Environment(\.accessibilityReduceMotion)` is true. Only opacity transitions remain.

### 2.4 Geometry

| Token | Value | Use |
|---|---|---|
| `Radii.compact` | 8pt | Small chips, badges |
| `Radii.default` | 12pt | Cards, panels |
| `Radii.large` | 18pt | Drop zone, onboarding panels |
| `Radii.pill` | 980pt | Privacy badge, preset picker |

Use `.continuous` corner style (`squircle`) — never `.circular` or `.rounded` (sharp bezier).

### 2.5 Motion

| Name | Spec | When |
|---|---|---|
| `Motion.spring` | spring(response:0.35, dampingFraction:0.7) | Physical press, drag, hover |
| `Motion.smooth` | timingCurve(0.4, 0, 0.2, 1, duration:0.4) | Progress fills, color fades |
| `Motion.snappy` | timingCurve(0.25, 0.46, 0.45, 0.94, duration:0.15) | Chip appear, badge pop |
| `Motion.cardEnter` | timingCurve(0.05, 0.7, 0.1, 1.0, duration:0.28) | Job card insertion |

---

## 3. App Screens — Inventory and State Coverage

The OpenDesign state-coverage craft rule requires **all five states** for every interactive surface:
Loading, Empty, Error, Populated, Edge. Below is the complete screen inventory with each state
answered.

### 3.1 Main Window

**Purpose:** Job queue command center. Drag/drop intake + live progress sidebar.

**Layout:** Two-column `NavigationSplitView`
- Left (420–520pt): Job queue sidebar + drop zone
- Right (340–400pt): Activity stream (event log)

#### State Coverage: Main Window

| State | Condition | What to show |
|---|---|---|
| **Empty** | No jobs ever submitted | Centered drop zone (DropZoneView, 320pt wide), subtitle "Drop media files, or choose a file to get started", tonal hint text (rotating based on hovered intake button), "Try a visual demo" button |
| **Populated** | 1+ jobs | Compact drop zone at top (60pt tall), then LazyVStack of `JobCardView` items |
| **Loading** | App start (DB reading) | Skeleton cards (2–3 ghost rects with shimmer, 80pt tall each) |
| **Error** | DB startup failed | Error banner below top bar: "Database unavailable — jobs won't persist. Restart to try again." with retry icon |
| **Edge** | 50+ jobs in queue | Virtual scrolling (LazyVStack). Cards truncate title at 1 line. No layout break |

#### Top Bar

Contains (left → right):
1. "ForgeMedia" label (title3, semibold)
2. Spacer
3. Privacy badge — `lock.shield.fill` + "Privacy On" (success green) or `lock.open` + "Local Only" (warning amber). Capsule shape.
4. Preset picker (Picker, `.menu` style, 140pt wide, `.small` control size)
5. "Select Video" button (`.bordered`)
6. "Select Videos" button (`.bordered`)
7. "Select Folder" button (`.borderedProminent`)
8. Gear icon (`.borderless`, opens Settings sheet)
9. Sidebar toggle icon (`.borderless`, collapses/expands activity stream)

**Rule:** One `.borderedProminent` per top bar — "Select Folder" only. The others are `.bordered`.

### 3.2 Job Card (`JobCardView`)

**Purpose:** Shows one media processing job with phase, progress, and controls.

**Sizing:** Full sidebar width, min 80pt tall, expands to show multi-line phase label if needed.

#### Job Card Anatomy (top → bottom)

```
┌─────────────────────────────────────────────────┐
│  [file icon]  title.mp4               Phase badge│
│               Encoding segment 5 of 8…  ████░  │
│  [Cancel] [Open Output]                  72%    │
└─────────────────────────────────────────────────┘
```

- **File icon:** SF Symbol `doc.fill` or format-specific (`film`, `waveform.circle`)
- **Title:** 14pt medium, 1 line, truncated tail
- **Phase badge:** Colored capsule with phase name (see phase colors below)
- **Progress bar:** Custom linear fill, `Colors.accent` fill on `Colors.borderSoft` track. Height: 3pt
- **Fraction label:** 11pt monospaced, right-aligned
- **Phase label:** 12pt regular, `Colors.muted`, names the exact phase ("Encoding segment 5 of 8…")

#### State Coverage: Job Card

| State | Condition | Appearance |
|---|---|---|
| **idle** | Queued, not started | Grey badge "Ready", progress 0%, no cancel button |
| **preparing** | Setting up | Amber badge "Preparing", progress ~3% |
| **running** | Active FFmpeg | Accent blue badge "Running", animated progress fill, cancel button shown |
| **takingLonger** | >60s elapsed with <30% progress | Orange badge "Taking Longer", "This is taking longer than expected for this file size" |
| **paused** | User paused | Amber badge "Paused", resume button shown |
| **completed** | Exit 0 | Green badge "Done", "Open Output" button shown, no cancel |
| **completedWithWarnings** | Exit 0 + warnings | Teal badge "Done (warnings)", warning disclosure triangle |
| **failed** | Non-zero FFmpeg exit | Red badge "Failed", error message in phase label, retry button |
| **canceled** | User canceled | Grey badge "Canceled", "Retry" button shown |
| **recovered** | Resumed after restart | Purple badge "Recovered", progress resumes from checkpoint |

#### Phase Badge Colors

| Phase | Color token | Background |
|---|---|---|
| idle | `Colors.muted` | `Colors.borderSoft` |
| preparing / paused | `Colors.warning` | `Colors.borderSoft` |
| running | `Colors.accent` | `Colors.accentGlow` |
| takingLonger | `Colors.amber` | `Colors.amberGlow` |
| completed | `Colors.success` | `Colors.tealGlow` |
| completedWithWarnings | `Colors.teal` | `Colors.tealGlow` |
| failed | `Colors.danger` | `Colors.roseGlow` |
| canceled | `Colors.muted` | `Colors.borderSoft` |
| recovered | purple (custom) | purple@0.1 |

### 3.3 Activity Stream (`ActivityStreamView`)

**Purpose:** Right-pane live event log. Shows all job events newest-at-bottom.

**Layout:** ScrollView with pinned-bottom auto-scroll. Each event is a row.

#### Event Row Anatomy

```
[●] [filename.mp4]  Encoding segment 5 of 8…            72%  14:32:01
```

- Dot: colored by phase (use phase badge colors, 8pt diameter)
- Filename: 11pt medium, muted, max 120pt wide, truncated
- Message: 11pt regular, fg
- Fraction: 11pt monospaced accent, right-aligned, hidden for non-running phases
- Timestamp: 11pt monospaced muted

#### State Coverage: Activity Stream

| State | Condition | What to show |
|---|---|---|
| **Empty** | No events yet | Centered vertical stack: `waveform` SF Symbol (24pt, muted), "Activity will appear here as jobs run" (body, muted), hint "Start a job or run a demo to see live events" |
| **Populated** | Events present | LazyVStack, auto-scroll to bottom on new event |
| **Loading** | App start | 5 skeleton rows (shimmer) |
| **Edge** | 500+ events | Virtual scroll, group by job if > 50 events per job |

### 3.4 Drop Zone (`DropZoneView`)

**Purpose:** Drag target that accepts `.movie` UTTypes. Also used as compact banner when queue is non-empty.

**States:**

| State | Visual |
|---|---|
| Default | Dashed border (1.5pt, `Colors.borderSoft`), light `Colors.bg` fill, centered icon + text |
| Drag-targeted | Solid `Colors.accentGlow` background, `Colors.accent` border (2pt), scale 1.01 via `Motion.spring` |
| Dragging files over (invalid type) | Red tint bg, `Colors.danger` border, "Not a supported video format" label |

### 3.5 Menu Bar Popover (`MenuBarView`)

280pt wide, anchored to the menu bar film icon.

**Sections:**
1. Header — "ForgeMedia" label + privacy indicator
2. Active jobs list (max 3 shown) — mini progress gauge + filename + cancel button
3. "No active jobs" empty state
4. Footer — "Open ForgeMedia" button (left) + active count label (right)

**Design rule:** This panel is status-only. No intake actions. No preset picker. No start buttons.

### 3.6 Settings (`SettingsView`)

Three-tab `TabView` inside a `Settings {}` scene.

#### Tab 1: General
- Output folder picker (TextField + "Choose…" button)
- Default preset picker (`.menu` style)
- Max concurrent jobs segmented control (1 / 2 / 4)

#### Tab 2: Privacy
- Privacy On badge (locked, non-editable) — visual confirmation only
- Remote crash reports disabled (locked)
- Local AI toggle (Whisper/Ollama, off by default)
- Remote AI toggle (warning amber label when enabled)

#### Tab 3: Engine
- FFmpeg path TextField with live checkmark/xmark validity indicator
- Auto-detect buttons for each Homebrew candidate path
- Version label (read-only)
- Build label (read-only)

#### State Coverage: Settings

| State | Condition | Behavior |
|---|---|---|
| FFmpeg not found | Path invalid | `xmark.circle.fill` danger icon next to path field, red subtitle "Not found at this path" |
| FFmpeg found | Path valid | `checkmark.circle.fill` success icon |
| Remote AI enabled | Toggle on | Warning label renders in amber: "Sends data to an external API" |

---

## 4. Component Checklist (from components.manifest.json)

Before designing a new control, confirm it isn't already in the Apple component manifest.
Use these existing patterns first:

| Need | Use from manifest | Notes |
|---|---|---|
| Action button | `button-primary` / `button-secondary` | `.borderedProminent` = primary |
| Picker / dropdown | `select` | `.menu` pickerStyle |
| Text input | `input-text` | `.roundedBorder` textFieldStyle |
| Toggle | `toggle` | System toggle, no custom track |
| Progress bar | Custom (not in manifest) | 3pt height, squircle caps, accent fill |
| Badge/chip | `badge` | Capsule, `.continuous` corners |
| Card container | `card-surface` | `.thinMaterial` + `Radii.default` |
| Divider | `divider` | 0.5pt, `Colors.border` |
| Disclosure group | `disclosure-group` | System `DisclosureGroup` |

---

## 5. Anti-Slop Checklist (from craft/anti-ai-slop.md)

Run this before shipping any design artifact for ForgeMedia:

- [ ] No indigo anywhere (`#6366f1`, `#4f46e5`, `#4338ca`) — use `#0066cc` only
- [ ] No two-stop gradient on any surface — flat `Colors.bg` only
- [ ] No emoji in any heading, button, or list item — SF Symbols only
- [ ] SF Pro used for all text, not Inter / Roboto / system-ui generic
- [ ] All card corners use `.continuous` (squircle) — not `.rounded`
- [ ] `--accent` used ≤2 visible times per screen region
- [ ] No lorem ipsum — all copy refers to real ForgeMedia content
- [ ] No colored left-border card accent style
- [ ] No invented metrics ("10× faster")

---

## 6. State Coverage Audit Checklist (from craft/state-coverage.md)

For each new component or screen delivered, verify:

- [ ] **Loading** state (skeleton or spinner)
- [ ] **Empty** state (headline + explanation + CTA, no just a blank box)
- [ ] **Populated** state (the main designed state)
- [ ] **Error** state (plain-language cause + recovery action)
- [ ] **Edge** state (50+ items, 200-char filename, missing optional fields)

ForgeMedia-specific edge scenarios:
- Job title is a full absolute path (240 chars) — must truncate gracefully
- 200 jobs queued — virtual scroll, no layout break
- All jobs failed simultaneously — activity stream shows all failures, no panic layout
- Video file with no audio track — "No audio track" warning, not a crash

---

## 7. Interaction Feedback & Motion Rules

From `ForgeMediaApp/interaction-feedback-states.md` and craft/animation-discipline.md:

### Progress Labels (non-negotiable)

Every progress update MUST name the actual phase, not a generic placeholder:

| ❌ Never | ✅ Always |
|---|---|
| "Processing…" | "Encoding segment 5 of 8…" |
| "Please wait…" | "Probing video metadata" |
| "Working…" | "Transcribing segment 3 of 12 (Whisper)" |
| "Loading…" | "Reading database — 1,247 jobs" |
| "Analyzing…" | "Planning segment boundaries for 4:52:30 source" |

### Reduced Motion

```swift
// In every animated view:
@Environment(\.accessibilityReduceMotion) var reduceMotion

.animation(reduceMotion ? .none : ForgeMediaTokens.Motion.smooth, value: someValue)
```

Remove all `scale`, `offset`, `rotation`, and `blur` animations. Opacity only.

### Spring Targets

Use `Motion.spring` for physical actions (hover, press, drag, card insertion).  
Use `Motion.smooth` for fills (progress bar advancing, color tinting).  
Use `Motion.snappy` for micro-shows (badge appearing, tooltip, disclosure).

---

## 8. Accessibility Rules (from craft/accessibility-baseline.md)

- All interactive elements: minimum 44×44pt hit target
- Color contrast: 4.5:1 for body text, 3:1 for large text and icons
- Never rely on color alone — always pair color with shape, icon, or label
- `accessibilityLabel` on all icon-only buttons: `Image(systemName: "xmark.circle.fill").accessibilityLabel("Cancel job")`
- VoiceOver traverse order must follow visual left-to-right, top-to-bottom
- Dynamic Type: all text must scale with `.body`, `.callout`, `.caption2` styles (not fixed pt sizes)

---

## 9. Privacy-First Visual Language

Privacy is a first-class branding element:

- **Privacy badge** is always visible in the top bar and menu bar, never hidden
- **Badge states:**
  - Privacy On (all local) → `lock.shield.fill` + "Privacy On" in `Colors.success` on `Colors.borderSoft` capsule
  - Local Only (some non-cloud features enabled) → `lock.open` + "Local Only" in `Colors.warning`
  - Remote AI active → `network.badge.shield.half.filled` + "Remote AI On" in `Colors.danger` (rare, intentionally alarming)

- Settings tab 2 (Privacy) shows locked green rows for non-optional defaults — this gives users *visible* confirmation, not just trust
- No onboarding screen asks for permissions not needed — ForgeMedia requests no permissions beyond file access

---

## 10. macOS Platform Rules (HIG compliance)

| Rule | Rationale |
|---|---|
| Menu bar extra (film icon) must never run media work | Architectural constraint — UI thread only |
| Settings opens as `.settings` scene in menu bar | Standard macOS pattern (Cmd+,) |
| Main window: `WindowGroup` with `id: "main"` | Ensures window always opens on launch; `Window` scene skips if previously closed |
| App stays active after window close | `applicationShouldTerminateAfterLastWindowClosed` returns false |
| Cmd+W closes window, Cmd+Q quits | Standard; never override Cmd+Q |
| Title bar: use default (not hidden) | Privacy badge and system controls need visible title area |
| Toolbar: not used | Top bar is a custom HStack in the content view |
| Vibrancy: use `NSVisualEffectView` materials | Matches macOS system appearance automatically |

---

## 11. The Design Walkthrough — Screen by Screen

### Walk 1: First Launch (Empty State)

1. App opens. Single window, 920×580pt minimum.
2. Top bar visible: left "ForgeMedia" label, right privacy badge (success green), preset picker, three intake buttons, gear, sidebar toggle.
3. Main area: white-ish `Colors.bg` with a centered drop zone card. Card has dashed border, centered `arrow.down.circle` SF Symbol (32pt, muted), "Drop media files, or choose a file to get started" (body, muted), rotating hint capsule below.
4. Below drop zone card: "Try a visual demo" button (`.borderedProminent`, `.small` control size).
5. Right pane: Activity stream showing empty state (waveform icon, "Activity will appear here…").
6. Menu bar: film icon in menu bar, popover shows "No active jobs."

### Walk 2: User Drops a Video (Job Intake → Processing)

1. User drags `interview.mov` onto window.
2. Drop zone receives drag: `Colors.accentGlow` background animates in via `Motion.spring`, scale 1.01.
3. Drop accepted: drop zone shrinks to 60pt compact banner. `JobCardView` inserts via `Motion.cardEnter` asymmetric transition.
4. Card shows: idle state briefly → immediately transitions to preparing (amber badge) → running (blue badge, progress fill begins animating).
5. Phase label updates: "Probing media metadata" → "Planning segment boundaries" → "Encoding segment 1 of 3…" → "Encoding segment 2 of 3…" etc.
6. Activity stream right pane receives rows as events emit, auto-scrolls to bottom.
7. Job completes: card phase badge turns green "Done", progress bar fills 100%, "Open Output" button appears.

### Walk 3: Settings (Privacy Tab)

1. User clicks gear → Settings window opens (460×360pt).
2. Three tabs: General, Privacy, Engine.
3. Privacy tab: Two locked green rows with `checkmark.circle.fill` icons confirm defaults. Two opt-in toggles for AI features (both off).
4. Tapping Remote AI toggle: label turns amber "Sends data to an external API". Checkbox state persists.

### Walk 4: Menu Bar Quick-Check

1. User is in another app.
2. Clicks film menu bar icon.
3. Popover appears (280pt). Header shows "ForgeMedia" + green "Local" badge.
4. One active job visible: title, mini circular gauge, phase label, cancel X button.
5. "Open ForgeMedia" button at bottom: click brings main window to front.

### Walk 5: Job Failure Recovery

1. FFmpeg exits non-zero (incompatible codec, corrupt file).
2. Card transitions to failed state: `Colors.danger` badge "Failed", phase label shows error message.
3. Activity stream shows the error event with `xmark.circle` icon and red dot.
4. "Retry" button appears on card. Clicking retries from scratch (phase resets to idle → preparing).

---

## 12. File Naming and Delivery

When delivering design artifacts for ForgeMedia:

- Screen name format: `FM-[screen]-[state].fig` or `FM-[screen]-[state].png`
- Component name format: `ForgeMedia/[ComponentName]/[state]`
- Export dimensions: `@1x` = 1pt = 1px (macOS), `@2x` for Retina
- Accent color deliverable: export ForgeMedia color swatch as `forgemedia-tokens.json`
- All components in dark-adapted state: ForgeMedia uses system materials that adapt — deliver light mode; dark mode adaptation is automatic via NSVisualEffectView

---

## 13. What NOT to Design

These are out-of-scope for the current version and must not be added:

- Onboarding flow / welcome screen — app starts with empty state, no tutorial
- Social sharing features — privacy-first, no share sheets
- Collaboration or cloud sync UI — deliberately excluded
- Animated hero/splash screen — app opens to main window immediately
- In-app browser, web views — all processing is local
- Analytics dashboard — no analytics collected
- Notifications/alerts outside the activity stream — no modal popups during processing
- Any screen that requires network connectivity icons (WiFi bars, cloud sync spinners)

---

## 14. Quick-Reference Token Map (copy-paste ready)

```swift
// Background & surfaces
ForgeMediaTokens.Colors.bg              // #f5f5f7 — window background
ForgeMediaTokens.Glass.surface          // .thinMaterial — card fill
ForgeMediaTokens.Colors.borderSoft      // rgba(232,232,237,0.6) — card stroke

// Text
ForgeMediaTokens.Colors.fg              // #1d1d1f — primary
ForgeMediaTokens.Colors.fgSecondary     // #424245 — secondary
ForgeMediaTokens.Colors.muted           // #6e6e73 — hint/caption

// Actions
ForgeMediaTokens.Colors.accent          // #0066cc — one per panel
ForgeMediaTokens.Colors.accentGlow      // #0066cc@0.12 — drag hover bg

// Semantic
ForgeMediaTokens.Colors.success         // #1a8c5c
ForgeMediaTokens.Colors.warning         // #b7791f
ForgeMediaTokens.Colors.danger          // #d43b3b

// Motion
ForgeMediaTokens.Motion.spring          // physical interactions
ForgeMediaTokens.Motion.smooth          // progress/color fills
ForgeMediaTokens.Motion.cardEnter       // job card insertion
```

---

*This brief was written against ForgeMedia v1.0 (June 2026). Update sections 3–5 when new screens are added.*
