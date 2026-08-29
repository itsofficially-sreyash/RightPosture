# Iteration 19 — Cues and controls

## Depends on

Iteration 18.

## Build

- One deduplicated haptic and short sound per degraded rep.
- Reuse voice/haptic settings; add sound toggle only if separate channel exists.
- Suppress cues in background and tests.

## Exit

- Rebuilds cannot replay cues.
- Disabled channels stay silent.
- Consecutive degraded reps each cue at most once.

## Cut

No exercise-specific sounds or audio package change.

## Completed — 2026-08-29

- Added one heavy haptic and one short Flutter system alert for each degraded rep.
- Added persisted Sound cues setting beside existing Voice and Haptic controls.
- Warning, good, calibration, depth, and tracking-loss events produce no degraded cue.
- Deduplication key combines exercise/set identity and rep number, so rebuilds cannot replay cues and consecutive degraded reps remain independent.
- Disabled and backgrounded degraded events are consumed without output and cannot replay after enabling/resuming.
- Lifecycle pause suppresses cue channels and interrupts pending audio.
- Cue callbacks remain asynchronous and outside pose inference.
- Reused Flutter `SystemSound`; no package, asset, or exercise-specific sound added.
- Verification: `flutter analyze`, 161 tests, and debug APK build passed.
- Hardware pending: verify alert volume, vibration strength, foreground/background suppression, and consecutive degraded reps.
