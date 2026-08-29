# Iteration 12 — Detailed set summary

## Status

Software complete on 2026-08-28. Iterations 10–11 remain intentionally deferred for later exercise work.

## Depends on

Iteration 06 and exposed exercise slices.

## Goal

Explain each set without chart dependency.

## Build

- Add component scores, averages, best/lowest rep, consistency score, quality distribution.
- Add tappable lightweight rep timeline and accessible details.
- Handle empty, calibration-only, clean, warning, degraded, missing-metric states.

## Exit

- Calibration/unavailable metrics never lower score.
- Labels follow selected exercise.
- Timeline works at 320 px and 200% text scale.

## Cut

Flutter widgets only. No chart package.

## Software evidence

- Added weighted Form Score, component scores, averages, consistency, best/lowest rep, and quality counts/percentages.
- Calibration reps and unavailable metrics are excluded; fewer than two evaluated reps shows `Not enough data`.
- Added exercise-aware component labels and tappable horizontal rep timeline.
- Rep details expose feedback, ROM, tempo, return time, confidence, and bilateral timing when available.
- Empty, calibration-only, warning, degraded, and missing-metric paths are covered.
- Timeline interaction passes at 320 px and 200% text scaling.
- `flutter analyze`: no issues.
- `flutter test`: 126 tests passed.
- Debug APK built successfully.
