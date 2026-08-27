# color_palette.md
Colors below were pixel-sampled directly from the uploaded reference image (not estimated/guessed) using multiple sample points per surface, averaged for consistency. PNG compression and anti-aliasing mean these are close but not pixel-perfect — if exact brand-accuracy matters, re-sample the source file in a design tool (Figma eyedropper) before finalizing. Flagging this honestly rather than presenting sampled values as certified-exact.

## Core palette (extracted from source)

| Token | Hex | Sampled from |
|---|---|---|
| `accent-lime` | `#D6FF5A` | Full-bleed backgrounds ("Get ready", "Congratulation" screens), FAB button, progress bar fill |
| `bg-base` | `#15161B` | Screen background (Browse, Home, Workout Detail dark areas) |
| `surface-card` | `#1F2025` | Card backgrounds (trainer card, list items) |
| `surface-card-elevated` | `#2D2D35` | Nested/elevated cards, dark circle behind checkmark on Congratulations screen |
| `text-primary` | `#FFFFFF` | Headings, primary body text on dark backgrounds |
| `text-muted` | `#BEBEC6` | Secondary/body copy on dark backgrounds (About paragraph text) |

## Gradient/variance note
The lime accent isn't perfectly flat across the kit — sampled values ranged `#D3FA63` to `#D6FF5A` to `#DBFC71` across different screens/areas, likely a subtle gradient or lighting effect in the original mockup. Treat `#D6FF5A` as the standard flat accent for implementation; if the team wants to replicate the gradient look, that needs the original design file, not deducible from a flat screenshot sample.

## Semantic colors — NOT in the source kit, proposed to fit it
The kit has no visible error/warning states to sample (it's a browsing/dashboard kit, not a status-driven UI). These are proposed additions matching the kit's dark-background, high-contrast-accent aesthetic — flag as new, not extracted:

| Token | Hex | Use |
|---|---|---|
| `status-good` | `#D6FF5A` (reuse accent-lime) | Rep status: good — reuses the kit's existing positive/energetic color, no new hue needed |
| `status-warning` | `#FFB84D` (proposed) | Rep status: warning — warm amber, readable against `bg-base`, doesn't clash with lime |
| `status-degraded` | `#FF5A5A` (proposed) | Rep status: degraded — red, standard alert convention, tested for contrast against dark backgrounds |

If the team has brand guidance for warning/error colors already, override these — they're a reasonable default, not a locked brand decision.

## Usage mapping for this app (per screens.md / ui/*.md)
- `bg-base` — Exercise Select, Live Session (behind camera feed), Session Summary background
- `accent-lime` — Onboarding full-bleed background, primary CTA buttons, progress bar, "good" status indicator, active/selected states
- `surface-card` / `surface-card-elevated` — exercise selection cards, summary stat cards, rep checklist rows
- `status-warning` / `status-degraded` — live rep status indicator and summary rep checklist markers only; do not use these as general UI accent colors, keep them scoped to evaluation status so they stay meaningful

## Explicitly not extracted
Trainer-profile-specific colors, rating-star colors, workout-difficulty-badge colors — these belong to kit screens outside our scope (decision.md D13). Not sampled, not needed.
