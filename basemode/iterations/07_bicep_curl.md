# Iteration 07 — Bicep curl vertical slice

## Status

Software complete on 2026-08-28. Debug builds expose a device-tuning preview; release card remains hidden until three target-device sets pass.

Device correction: normalized torso translation invalidates curl attempts, preventing squat motion from calibrating or counting as curls. Debug preview appears after the primary Squat card.

## Depends on

Iteration 06.

## Build

Profile, metrics, detector, bilateral mode, thresholds, setup guidance, feedback, summary labels, selection card, tests, device tuning.

## Exit

- Full select-to-summary flow works.
- Partial curl is evaluated; duplicate frames do not double count.
- Three scripted target-device sets count correctly.
- Card stays hidden until gate passes.

## Cut

No abstraction beyond behavior shared with squat.
