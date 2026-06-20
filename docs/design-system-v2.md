# ForgeMedia Design System v2 — macOS 27 Golden Gate

> Visual refresh addressing "plain/boring" feedback while conforming to Apple HIG.
> Key references: macOS 27 UI Kit, Apple HIG Materials, SF Symbols 7, GeexArts motion language.

---

## What Changed & Why

| Problem (v1) | Solution (v2) |
|---|---|
| Flat `#f5f5f7` background | Atmospheric gradient mesh — subtle warmth radiating from top-center |
| Cards are pure `#ffffff` | Multi-layer glass cards with `backdrop-filter` at varying blur depths |
| Single accent `#0066cc` for everything | Expanded palette: primary blue, warm progress amber, deep teal success, rose accent for creative warmth |
| No depth differentiation | 4-tier material system: Base → Surface → Elevated → Floating (each with distinct blur + saturation) |
| Type is uniform 13px | Display scale for heroes (20px-28px), tighter tracking, SF Pro Display for headings |
| Drop zone is a dashed box | Animated glass panel with ambient glow pulse and icon morph on drag-over |
| Progress bars are flat fills | Gradient fills with subtle shimmer animation |
| No micro-texture | Subtle grain overlay on window chrome (0.5% opacity noise) |
| Static phase badges | Animated badges with pulse/keyframe transitions |
| Icons are Unicode text | SF Symbols-inspired monoline SVG icons at 1.6px stroke |

---

## Color Architecture v2

### Atmospheric Base
```
Window background: radial-gradient from warm 5% opacity at top fading to cool neutral
- Top center:   rgba(210,180,160,0.04)  ← warm rose/gold atmosphere
- Mid:          transparent
- Bottom:       rgba(200,210,220,0.03)  ← subtle blue shift
```

### Primary Palette
| Role | Token | Value | Use |
|---|---|---|---|
| Window bg | `--fm-bg` | `#f5f5f7` with gradient mesh | Main canvas |
| Surface | `--fm-surface` | `rgba(255,255,255,0.78)` | Cards (glass) |
| Surface elevated | `--fm-surface-raised` | `rgba(255,255,255,0.88)` | Hovered cards, sheets |
| Surface floating | `--fm-surface-float` | `rgba(255,255,255,0.95)` | Modals, popovers |

### Accent Family (Expanded)
| Role | Token | Value | Use |
|---|---|---|---|
| Primary action | `--fm-accent` | `#0066cc` | Buttons, focus, selected |
| Primary hover | `--fm-accent-strong` | `#0077ed` | Hover, active progress |
| Progress/energy | `--fm-amber` | `#d4890c` | In-progress glow, segment indicators |
| Success | `--fm-success` | `#1a8c5c` | Completion, verified checks |
| Creative warmth | `--fm-rose` | `#c4456e` | Brand accent moments, empty state hero |
| Deep info | `--fm-teal` | `#0b7b8c` | Metadata, secondary info |

### Semantic States
| State | Token | Value |
|---|---|---|
| Warning | `--fm-warning` | `#b7791f` |
| Danger | `--fm-danger` | `#d43b3b` |
| Success bg | `--fm-success-bg` | `rgba(26,140,92,0.06)` |
| Progress bg | `--fm-amber-bg` | `rgba(212,137,12,0.06)` |

---

## Material System (4 Tiers)

```
Tier 1 — BASE:     blur(40px) saturate(180%) opacity(0.72)  ← Window
Tier 2 — SURFACE:  blur(20px) saturate(160%) opacity(0.78)  ← Cards, panels
Tier 3 — ELEVATED: blur(12px) saturate(140%) opacity(0.88)  ← Hover, active cards
Tier 4 — FLOATING: blur(8px)  saturate(120%) opacity(0.95)  ← Modals, popovers
```

---

## Typography Scale v2

| Role | Size | Weight | Tracking | Use |
|---|---|---|---|---|
| Hero display | 28px | 600 | -0.02em | Empty state headline |
| Section header | 20px | 600 | -0.015em | Panel titles |
| Card title | 14px | 600 | -0.01em | Job names |
| Body | 13px | 400 | 0 | Descriptions, metadata |
| Label | 12px | 500 | 0.01em | Progress labels, actions |
| Micro | 11px | 500 | 0.02em | Badges, timestamps |
| Mono | 11px | 400 | 0 | Confidence labels, checksums |

---

## Animation Tokens v2

| Pattern | Duration | Easing | Notes |
|---|---|---|---|
| Button press | 100ms | `cubic-bezier(0.2,0,0,1)` | Scale 0.97, no bounce |
| Card enter | 280ms | `cubic-bezier(0.05,0.7,0.1,1)` | Spring-equivalent, no overshoot |
| Card hover elevation | 200ms | `cubic-bezier(0.25,0.46,0.45,0.94)` | Y: -2px, shadow expand |
| Progress fill | 400ms | `cubic-bezier(0.4,0,0.2,1)` | Smooth, no flash |
| Phase badge pulse | 1.4s loop | `ease-in-out` | Running dot |
| Drop zone breathe | 2.4s loop | `ease-in-out` | Ambient glow pulse |
| Success reveal | 280ms | `cubic-bezier(0.34,1.56,0.64,1)` | One-shot spring |

---

## Component Specs v2

### Window Chrome
- 10px continuous corner radius (squircle approximation)
- Traffic lights: 12px, with hover inner highlights
- Title bar: 52px, `-webkit-app-region: drag`
- Subtle grain overlay: SVG noise at 0.5% opacity

### Drop Zone
- Solid border (not dashed) at `rgba(0,0,0,0.08)`
- Glass surface (Tier 2 material)
- Ambient glow: radial-gradient pulse behind icon on idle
- On drag-over: border → accent color, background → accent glow 8%, scale → 1.004
- Icon morphs from ↓ to film icon, 280ms spring

### Job Card
- Glass surface (Tier 2 material)
- Hover: elevates to Tier 3, Y: -2px, shadow deepens
- Progress bar: gradient fill (accent → amber for running, accent → success for complete)
- Actions: revealed on hover, always visible on touch
- Delete: swipe-left gesture

### Phase Badge
- Pill geometry (980px radius)
- Running: amber tint + pulsing dot
- Completed: teal tint + checkmark
- Failed: rose tint + X mark
- Transition: 200ms crossfade on phase change

---

## Dark Mode v2

Dark mode is NOT an inversion. Backgrounds spread apart:
- Base: `#121214` → `#1c1c1e` → `#2c2c2e` → `#3a3a3c`
- Glass: `rgba(28,28,30,0.72)` with `blur(40px) saturate(120%)`
- Accent brightens: `#0a84ff`, `#e8a817`, `#30b87c`, `#e05a7c`
- Atmospheric gradient shifts to cooler tones: `rgba(80,100,140,0.06)`