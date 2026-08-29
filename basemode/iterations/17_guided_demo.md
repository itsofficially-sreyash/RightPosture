# Iteration 17 — First-visit guided demo

## Depends on

Iterations 05, 14 and exposed exercise profiles.

## Build

- Run five instruction/posture-check cycles.
- Select next instruction from current measurable posture.
- Persist completion per exercise; add Replay Demo.

## Exit

- Every instruction follows fresh posture check.
- Later visits skip after persisted completion.
- Only supported metrics generate instruction.

## Cut

No video tutorial, generated script, or extra onboarding flow.

## Completed — 2026-08-29

- Added first-visit demo gating and persisted completion per implemented exercise.
- Added five automatic instruction/posture-check cycles, spaced by 2 seconds and requiring a fresh ready pose frame.
- Pose loss, low confidence, stale frames, and unsupported metrics cannot advance progress.
- Guidance uses only measured knee angle, elbow angles, or bilateral arm elevation supported by the selected exercise.
- Voice coaching speaks each accepted instruction when enabled; visible text remains authoritative.
- Added per-card Replay Demo without adding a top-level onboarding control.
- Demo exit records nothing; persistence failure never blocks normal preparation/countdown.
- Verification: `flutter analyze`, 153 tests, and debug APK build passed.
- Hardware pending: confirm real-device instruction timing, posture thresholds, camera switching, and spoken guidance.
