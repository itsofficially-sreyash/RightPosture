# Iteration 06 — Core UI Flow

## Goal

Build complete P0 flow around tested state, using design tokens and adaptive layouts.

## Scope

- Add theme tokens for colors, spacing, radius, and typography.
- Build Exercise Select with squat only initially.
- Build Live Session with camera, skeleton, rep count, calibration/tracking status, reason text, progress, and End Set.
- Build Session Summary with Form Score, total reps, checklist, degradation callout, and Restart.
- Add loading, empty, and error states plus accessible labels and 48dp touch targets.
- Use width-based layouts; keep readable content constrained on large screens.

## Not in scope

- Onboarding, audio, elaborate animation, export, session history, lunge, custom routing package, or bottom navigation.

## Tests

- Widget tests for select, live states, summary variants, and restart.
- Text scaling and compact-width smoke checks; no overflow.
- Manual keyboard/touch navigation check where supported.

## Exit gate

Synthetic end-to-end flow works without camera, then real camera flow reaches summary on iQOO.

