# Iteration 09 — Shoulder press vertical slice

## Status

Software complete on 2026-08-28. Debug builds expose a device-tuning preview; release card remains hidden until three target-device sets pass.

## Depends on

Iteration 08.

## Build

Add wrist travel, elbow extension, overhead completion, arm timing/symmetry, torso stability, guidance, feedback, summary, tests, and card.

## Exit

- Incomplete overhead movement gets range feedback.
- Both hands return before simultaneous completion.
- Three target-device sets pass.

## Cut

No exercise-specific controller.

## Software evidence

- Shared bilateral arm sample/controller path handles wrist travel, elbow extension, timing, torso stability, ROM, and tempo.
- Both hands must return to rack position before one rep completes.
- Incomplete overhead attempts complete with evidence and receive overhead-range feedback.
- Shoulder Press uses profile-owned setup copy, shared automatic countdown, and first-3-rep calibration.
- `flutter analyze`: no issues.
- `flutter test`: 124 tests passed.
- Debug APK built successfully.
