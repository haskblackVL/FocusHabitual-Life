---
name: Executive Precision
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#434655'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#737686'
  outline-variant: '#c3c6d7'
  surface-tint: '#0053db'
  primary: '#004ac6'
  on-primary: '#ffffff'
  primary-container: '#2563eb'
  on-primary-container: '#eeefff'
  inverse-primary: '#b4c5ff'
  secondary: '#4b41e1'
  on-secondary: '#ffffff'
  secondary-container: '#645efb'
  on-secondary-container: '#fffbff'
  tertiary: '#943700'
  on-tertiary: '#ffffff'
  tertiary-container: '#bc4800'
  on-tertiary-container: '#ffede6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dbe1ff'
  primary-fixed-dim: '#b4c5ff'
  on-primary-fixed: '#00174b'
  on-primary-fixed-variant: '#003ea8'
  secondary-fixed: '#e2dfff'
  secondary-fixed-dim: '#c3c0ff'
  on-secondary-fixed: '#0f0069'
  on-secondary-fixed-variant: '#3323cc'
  tertiary-fixed: '#ffdbcd'
  tertiary-fixed-dim: '#ffb596'
  on-tertiary-fixed: '#360f00'
  on-tertiary-fixed-variant: '#7d2d00'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  display-hero:
    fontFamily: Geist
    fontSize: 56px
    fontWeight: '700'
    lineHeight: 64px
    letterSpacing: -0.035em
  headline-xl:
    fontFamily: Geist
    fontSize: 40px
    fontWeight: '600'
    lineHeight: 48px
    letterSpacing: -0.03em
  headline-xl-mobile:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.025em
  headline-lg:
    fontFamily: Geist
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Geist
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Geist
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
    letterSpacing: -0.01em
  body-md:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: -0.005em
  body-sm:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  label-numeric:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: -0.01em
  label-caps:
    fontFamily: Geist
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.06em
  label-action:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '500'
    lineHeight: 20px
    letterSpacing: -0.01em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  gutter-mobile: 1rem
  margin: 3rem
  margin-mobile: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style

This design system embraces Modern Swiss Neo-Minimalism engineered specifically for high-performing executives, knowledge workers, and polymaths. It rejects decorative noise, arbitrary ornament, and synthetic visual effects in favor of razor-sharp spatial discipline, deliberate typography, and high-clarity data architecture.

The visual tone reflects calm mastery, intellectual vigor, and absolute focus. Drawing directly from the rigor of International Typographic Style (Swiss Style) fused with modern product craftsmanship (Apple, Stripe), the interface treats whitespace not as empty canvas, but as an active structural element that reduces cognitive friction. High-contrast type hierarchy, deliberate hairline structures, and purposeful cobalt focal points project an unyielding standard of professional excellence and functional elegance.

## Colors

The palette operates under a high-efficiency light-mode discipline. The canvas is locked to pure crystalline white (`#ffffff`), establishing a non-fatiguing, luminous baseline for intense analytical thought and habit tracking. 

- **Primary (`#2563eb`)**: Electric Cobalt Sapphire. Reserved strictly for primary callouts, completion milestones, focus triggers, and active states. It cuts decisively against neutral backgrounds without visually vibrating.
- **Secondary (`#4f46e5`)**: Deep Modern Indigo. Acts as a sophisticated complement for meta-metrics, polymath domain classification, and multidimensional habit analytics.
- **Neutral Deep (`#0f172a`)**: Slate 900. Utilized for high-priority typography, sharp metrics, and critical structural lines, guaranteeing strict accessibility and commanding readability.
- **Surface Containers (`#f8fafc` and `#f1f5f9`)**: Slate 50 and Slate 100. Form subtle structural cards, table rows, and dashboard blocks without introducing visual weight.
- **Structural Outlines (`#e2e8f0`)**: Slate 200. Subtle, crisp 1px borders providing architectural definition without visual clutter.

## Typography

The typographic hierarchy is anchored on Geist for its Swiss grotesque geometry, neutral modern neutrality, and razor-sharp rendering on Retina displays. Letter-spacing tightens progressively as scale increases, delivering punchy, authoritative headlines and highly legible running text.

JetBrains Mono serves a specialized role for quantitative data: streaks, performance intervals, session clocks, habit completions, and telemetry readouts. Its tabular figures prevent horizontal jitter when values refresh in real-time. All numerical metrics and data-dense dashboards must use tabular figures.

## Layout & Spacing

The layout is grounded on a disciplined 8-point base grid coupled with a 12-column responsive layout for desktop dashboards and a single-column stacked layout on mobile.

- **Desktop (1200px+)**: 12 columns with 24px (`1.5rem`) gutters and generous 48px (`3rem`) screen margins. Max content container caps at 1440px to retain scan efficiency.
- **Tablet (768px - 1199px)**: 8 columns with 20px gutters and 32px margins. Side rails compress into sticky iconography.
- **Mobile (< 768px)**: 4 columns or single stack, with 16px (`1rem`) gutters and 20px (`1.25rem`) safe-margin boundaries.

Micro-spacing rules:
- Interactive inputs and metrics adopt strict vertical padding (`0.75rem` / 12px) paired with horizontal padding (`1rem` / 16px).
- Grouped habit metrics and sequential node trackers maintain consistent 8px (`space-sm`) gaps to preserve grouping unity.

## Elevation & Depth

Visual hierarchy is constructed through structural tonal layering and ultra-crisp, diffused ambient shadows rather than dense drop-shadows or skeuomorphic bevels.

- **Base Layer (Level 0)**: `#ffffff` canvas. Completely flat.
- **Surface Container (Level 1)**: `#f8fafc` or `#f1f5f9` card modules bounded by a single-pixel hairline border in `#e2e8f0`. Shadow is absent or microscopic: `0 1px 2px 0 rgba(15, 23, 42, 0.04)`.
- **Raised Interactive Cards / Hover (Level 2)**: Elevated elements transition dynamically with an ambient shadow: `0 4px 16px -2px rgba(15, 23, 42, 0.05), 0 2px 4px -1px rgba(15, 23, 42, 0.03)` with a hairline border `#cbd5e1`.
- **Floating Modals / Popovers (Level 3)**: Pure white background with layered atmospheric projection: `0 20px 35px -8px rgba(15, 23, 42, 0.08), 0 8px 12px -4px rgba(15, 23, 42, 0.03)` and a crisp `#e2e8f0` edge.

No muddy shadows or high-opacity drop fills are permitted. Depth must remain airy, crisp, and optical.

## Shapes

The design language balances mathematical precision with approachable ergonomics. The geometry employs smooth continuous corners (`squircle` perception) without crossing into playful pill territory.

- Standard cards, dashboard panels, and focus modules leverage `rounded-2xl` (1rem / 16px) corner radii.
- Interactive controls, buttons, form inputs, and status badges take `0.5rem` (8px) for crisp tactical interaction.
- Micro-elements such as streak indicator blocks and checkmark icons use `0.375rem` (6px).
- Status dots and live recording pulses are fully circular (`rounded-full`).

## Components

### Buttons
- **Primary**: Solid Cobalt Sapphire (`#2563eb`), white typography (`#ffffff`), `font-weight: 500`, 8px radius. Subtle micro-scale on click (`0.985`). Hover state transitions to `#1d4ed8`.
- **Secondary / Outline**: Crisp `#ffffff` fill with a 1px `#e2e8f0` border, `#0f172a` text. Hover shifts background to `#f8fafc` and border to `#cbd5e1`.
- **Ghost**: Transparent fill, `#475569` text, transitioning to `#f1f5f9` fill and `#0f172a` text on hover.

### Cards & Focus Modules
- Engineered with `rounded-2xl` corners, 1px `#e2e8f0` borders, `#ffffff` surface, and Level 1 elevation.
- Internal padding is locked to `1.5rem` (24px). Headers separate metadata with a clean border-bottom divider line using `#f1f5f9`.

### Input Fields
- Flat `#ffffff` surface, 1px `#e2e8f0` boundary, 8px radius, `font-size: 14px`.
- Placeholder text in `#94a3b8`.
- Active focus state: border shifts to `#2563eb` with a 3px ring in `rgba(37, 99, 235, 0.12)`. No harsh browser outlines.

### Checkboxes & Habit Rings
- Checkboxes: 18x18px squares with 5px corner radius. Unchecked state uses `#ffffff` with a 1.5px `#cbd5e1` boundary. Checked state instantly fills with `#2563eb` featuring an optic-white check icon.
- Habit Progress Indicators: Concentric SVG rings with 2.5px track widths. Background tracks use `#f1f5f9`; active progress tracks use `#2563eb` or `#4f46e5` with crisp geometric terminations (`stroke-linecap: round`).

### Chips & Filters
- Compact 28px height, 6px radius. `#f8fafc` background with `#0f172a` text. Selected chips transition to `#0f172a` background with `#ffffff` text, or high-contrast cobalt accents.

### Specialized Polymath & Habit Tracking Components
- **Streak Ledger**: Monospace numerical tallies via `JetBrains Mono` enclosed within minimal grey badge enclosures (`#f1f5f9`), accompanied by a micro status beacon.
- **Cognitive Matrix Card**: Split-column performance view comparing planned executive outcomes against completed polymath blocks, delimited by vertical `#f1f5f9` hair dividers.