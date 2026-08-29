# Iteration 13 — Workout and set comparison

## Status

Software complete on 2026-08-28. Workout history remains memory-only and disappears on explicit reset/app restart.

## Depends on

Iteration 12.

## Goal

Compare sets inside current workout.

## Build

- Add immutable `CompletedSet` and `WorkoutState`.
- Add Next Set, Change Exercise, Finish Workout, explicit reset.
- Compare same-exercise Form Score, ROM, tempo, degradation point, consistency, issues.

## Exit

- Each completion appends exactly one snapshot.
- New set clears live engines and baseline.
- Cross-exercise raw metrics are never ranked.

## Cut

No durable storage yet.

## Software evidence

- Added immutable `CompletedSet` snapshots and `WorkoutState`.
- End Set appends once; duplicate completion cannot append again.
- Next Set preserves exercise/history while resetting reps, detector, smoothing, countdown, calibration, baseline, and feedback.
- Change Exercise preserves workout history; Finish Workout opens grouped workout summary; New Workout explicitly clears it.
- Same-exercise sets compare Form Score within tolerance and show ROM, tempo, degradation point, consistency, and issue counts.
- Different exercises are grouped and never directly ranked by raw movement metrics.
- `flutter analyze`: no issues.
- `flutter test`: 130 tests passed.
- Debug APK built successfully.
