---
name: Warm Editorial Executive Wellness
colors:
  surface: '#fef8f5'
  surface-dim: '#ded9d5'
  surface-bright: '#fef8f5'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f8f2ef'
  surface-container: '#f3ede9'
  surface-container-high: '#ede7e4'
  surface-container-highest: '#e7e1de'
  on-surface: '#1d1b19'
  on-surface-variant: '#53433f'
  inverse-surface: '#32302e'
  inverse-on-surface: '#f5f0ec'
  outline: '#85736e'
  outline-variant: '#d8c2bc'
  surface-tint: '#8a4f3d'
  primary: '#6e3828'
  on-primary: '#ffffff'
  primary-container: '#8a4f3d'
  on-primary-container: '#ffcec0'
  inverse-primary: '#ffb59f'
  secondary: '#52634f'
  on-secondary: '#ffffff'
  secondary-container: '#d2e5cc'
  on-secondary-container: '#566753'
  tertiary: '#673c2b'
  on-tertiary: '#ffffff'
  tertiary-container: '#825340'
  on-tertiary-container: '#ffcebc'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbd0'
  primary-fixed-dim: '#ffb59f'
  on-primary-fixed: '#370e03'
  on-primary-fixed-variant: '#6d3827'
  secondary-fixed: '#d5e8cf'
  secondary-fixed-dim: '#b9ccb4'
  on-secondary-fixed: '#101f10'
  on-secondary-fixed-variant: '#3b4b39'
  tertiary-fixed: '#ffdbce'
  tertiary-fixed-dim: '#f6b9a1'
  on-tertiary-fixed: '#321205'
  on-tertiary-fixed-variant: '#663c2b'
  background: '#fef8f5'
  on-background: '#1d1b19'
  surface-variant: '#e7e1de'
typography:
  display-lg:
    fontFamily: Newsreader
    fontSize: 48px
    fontWeight: '400'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-lg-mobile:
    fontFamily: Newsreader
    fontSize: 36px
    fontWeight: '400'
    lineHeight: 44px
    letterSpacing: -0.01em
  headline-lg:
    fontFamily: Newsreader
    fontSize: 32px
    fontWeight: '400'
    lineHeight: 40px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Newsreader
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
  headline-sm:
    fontFamily: Newsreader
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 26px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.04em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1.5rem
  margin: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style

This design system embodies high-touch, executive-tier holistic wellness. It deliberately rejects cold, dark-mode cyberpunk tech tropes, fluorescent accents, and gamified dopamine loops. Instead, the interface draws from premium editorial journals, high-end architectural retreats, and quiet luxury print media. 

The emotional tone is restorative, composed, breathable, and deeply human. Interfaces feel unhurried, providing cognitive clarity for executives and high-performance individuals navigating high-stress lifestyles. The design movement pairs Warm Minimalism with Editorial Tactility: expansive natural whitespace, soft organic curves, muted tactile tones, and literary typography that respects the user's attention.

## Colors

The palette is rooted in grounding, natural earth tones. 

- **Primary (`#8A4F3D` - Warm Terracotta):** Anchors primary calls-to-action, key milestone highlights, and warm focus states. It conveys grounded warmth without the artificial urgency of synthetic reds or oranges.
- **Secondary (`#586955` - Muted Laurel Sage):** Used for restorative actions, completed wellness states, balance metrics, and contemplative tags.
- **Tertiary (`#B8826D` - Soft Rose Cedar):** Provides delicate accenting, gentle decorative fills, and secondary focal markers.
- **Neutral (`#272523` - Warm Deep Slate):** The primary text color. It avoids pure harsh black, providing soft contrast against parchment and off-white backdrops.

### Canvas & Surface Tokens
- `surface-canvas`: `#FAF8F5` (Alabaster Linen) — The foundation for all screens.
- `surface-card`: `#FFFFFF` (Pure Chalk) — Elevated resting surfaces.
- `surface-subtle`: `#F2EDE4` (Warm Sand Oat) — Recessed backgrounds, inactive containers, and soft segment tracks.
- `border-soft`: `#E6DFD5` (Muted Sandstone) — Low-contrast structural separation.
- `text-muted`: `#68635E` (Warm Mineral Ash) — Subheadings, tertiary labels, and secondary metadata.

## Typography

Typography establishes an editorial atmosphere:

- **Headlines (`Newsreader`):** Employs an optical, transitional serif to infuse calm, literary authority. It should be typeset primarily in normal/medium weights with slightly tighter tracking at large scales. Use italicized variants sparingly for emphasis or reflective quote treatments.
- **Body & Functional UI (`Plus Jakarta Sans`):** Provides clean, humanistic legibility with comfortable x-heights and warm, geometric aperture openings. It ensures effortless scanability for schedules, health logs, and interactive controls without clashing with the serif headlines.
- **Micro-labels (`label-md`, `label-sm`):** Set in subtle uppercase with deliberate letter spacing (`0.04em - 0.05em`) to structure metadata, metrics units, and category classifications cleanly.

## Layout & Spacing

The layout philosophy uses a disciplined, breathable fluid grid built around generous margins to evoke open space and mental ease:

- **Grid System:** A 12-column grid on desktop screens (`min-width: 1024px`) with a maximum content container width of `1200px`. Tablets (`768px - 1023px`) scale to an 8-column layout with `1.5rem` gutters. Mobile viewports (`<768px`) collapse to a single 4-column flow with `1rem` gutters and `1.25rem` outer margins.
- **Vertical Rhythm:** Generous vertical intervals are mandated between conceptual sections (`space-xl` to `3.5rem`), preventing information crowding. Modules breathe through generous internal card padding (`space-lg`).
- **Reflow Rules:** Executive dashboards reflow from multi-column metrics and side-by-side contemplative logs into single-column vertical journeys on mobile devices.

## Elevation & Depth

Visual hierarchy uses warm ambient lighting and soft tactile layering rather than synthetic drop shadows:

- **Surface Tiers:**
  - `Level 0 (Canvas)`: Flat `#FAF8F5`.
  - `Level 1 (Cards & Modules)`: Solid `#FFFFFF` bordered by `#E6DFD5` (`1px`) with an ambient diffused shadow: `0 8px 24px -6px rgba(39, 37, 35, 0.04)`.
  - `Level 2 (Dropdowns, Overlays & Floating Sheets)`: Raised surface with warm tinted dispersion: `0 16px 36px -8px rgba(39, 37, 35, 0.08)`, paired with a `1px` border of `#E6DFD5`.
- **Shadow Quality:** Shadows must always carry a subtle warm undertone (derived from `#272523`) rather than cold gray or pure black, mimicking natural daylight on textured cardstock.
- **Backdrop Overlays:** Modals and focus drawers use a soft linen scrim: `rgba(242, 237, 228, 0.75)` accompanied by a gentle `6px` blur.

## Shapes

The design uses balanced, natural curvature (`roundedness: 2`). Radii scale smoothly:

- **Standard Elements (Buttons, Inputs, Small Badges):** `0.5rem` (8px).
- **Cards & Content Modules:** `1rem` (16px) via `rounded-lg`.
- **Hero Containers, Sheet Dialogs, Modals:** `1.5rem` (24px) via `rounded-xl`.
- **Avatars, Sliders & Pills:** Fully pill-shaped (`9999px`) to reinforce tactile and organic touchpoints.

## Components

### Buttons
- **Primary:** Filled `#8A4F3D` with `#FFFFFF` text. Height `44px` on mobile, `48px` on desktop. Padding `0 1.5rem`. Smooth hover transition to `#764233`. Focus ring uses a `2px` offset with `rgba(138, 79, 61, 0.3)`.
- **Secondary (Contemplative):** Filled `#586955` with `#FFFFFF` text. Used for restorative completions or routine reflections.
- **Tertiary / Ghost:** Border `1px solid #E6DFD5`, transparent background, `#272523` text. Soft hover fill of `#F2EDE4`.

### Cards & Habit Blocks
- Constructed with `#FFFFFF` surface fill, `1px solid #E6DFD5` border, and `rounded-lg`.
- Internal padding is strictly `1.5rem`. Titles are displayed in `Newsreader` (`headline-sm`), accompanied by warm metadata in `label-sm`.

### Input Fields
- Background `#FFFFFF` with `1px solid #E6DFD5` border and `0.5rem` radius. 
- Height `44px`, text `body-md` in `#272523`. Placeholder styled in `#68635E` at 60% opacity.
- Active state transitions smoothly to `1px solid #8A4F3D` with a subtle `2px` focus halo in `rgba(138, 79, 61, 0.15)`.

### Chips & Filter Pills
- Inactive: Background `#F2EDE4`, border `1px solid transparent`, text `#68635E` (`label-md`).
- Active: Background `#FFFFFF`, border `1px solid #8A4F3D`, text `#8A4F3D`. Fully rounded pill shape (`9999px`).

### Checkboxes & Habit Trackers
- Size `22px x 22px` with `0.375rem` radius. 
- Inactive: `1.5px solid #E6DFD5` with `#FFFFFF` center.
- Active: Filled with either `#586955` (Sage) or `#8A4F3D` (Terracotta) displaying a crisp `#FFFFFF` checkmark, accompanied by an optional gentle haptic/scale bounce animation (1.05x).

### Mindful Reflection Modules (Domain-Specific)
- Clean, open journal prompts using `surface-subtle` (`#F2EDE4`) backgrounds, borderless textareas, and italicized `Newsreader` header cues.
- Progress visualization relies on continuous organic progress arcs using thin, warm strokes (`3px`) in Sage (`#586955`) over Sandstone tracks (`#E6DFD5`), avoiding harsh, data-heavy dashboard charts.