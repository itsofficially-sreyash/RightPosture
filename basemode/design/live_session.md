# ui/live_session.md
Priority: P0 (features.md). This is the screen judges watch most closely — the live pose-detection engine is the whole technical claim (project.md), don't let UI decoration compete with it.

## Layout
The kit's live-exercise screen (big rep numeral, progress bar, Previous/Next, background photo) is the closest reference pattern — but the background photo is REPLACED by the actual live camera feed with skeleton overlay. This is a deliberate deviation from the kit, not an oversight: showing the live camera + skeleton IS the product's core technical demonstration (project.md's differentiation claim, decision.md D11), a static photo background would hide it.

- Full-screen (or near-full-screen) live camera preview, skeleton overlay drawn on top in real time (`accent-lime` #D6FF5A for the skeleton lines/joints — high contrast against most backgrounds, matches the kit's accent usage).
- Rep counter: big bold numeral, top or bottom overlay on the camera feed (kit's "10" numeral treatment, design.md), `text-primary` white or `accent-lime`.
- Status indicator: small, unobtrusive — a colored dot/badge near the rep counter using `status-good`/`status-warning`/`status-degraded` (color_palette.md). During calibration (first 2-3 reps), show a distinct neutral "calibrating" state instead of any status color — don't imply a verdict that doesn't exist yet (screens.md, error_handling.md).
- Progress bar: reps completed vs. target, thin bar near the bottom, `accent-lime` fill on a dark track (kit pattern, design.md).
- P1: reason text (e.g. "knee angle drifting") appears briefly near the status indicator when a rep is flagged warning/degraded — don't leave it permanently on screen, it should surface at the moment of the flagged rep and fade after a few seconds.

## States
- **Calibrating** (first 2-3 valid reps, before baseline exists): pulsing/breathing neutral indicator, rep counter still increments normally.
- **Tracking, good**: status-good indicator, normal rep flow.
- **Tracking, warning**: status-warning indicator, brief on-screen cue (P1).
- **Tracking, degraded**: status-degraded indicator, stronger on-screen cue (P1: audio/visual per features.md).
- **No person in frame**: pause evaluation, show a neutral "step into frame" message overlay (error_handling.md) — do not show a stale rep counter or status as if tracking is still active.
- **Low confidence**: same "step into frame"-style neutral state, don't display a verdict computed from unreliable data (error_handling.md).

## Animation (design.md)
- Rep counter increment: scale-pulse (~150ms) on each completed rep — highest-value animation on this screen, this is what a judge's eye tracks.
- Status crossfade: 150-200ms fade between calibrating/good/warning/degraded states, never an instant cut.
- Progress bar: animated fill per rep, ~200-300ms easing.
- Performance constraint: verify these animations don't compete with camera/pose rendering frame budget on the actual loaner (execution/01, design.md performance note) — if there's any jank, cut UI animation before touching the pose pipeline's performance.

## Explicitly not building
- Previous/Next navigation (kit pattern) — there's nothing to navigate between, this is a live single-set session, not a browsable exercise library.
- "See all" link (kit pattern) — no library to link to.
