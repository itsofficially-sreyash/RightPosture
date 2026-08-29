# Iteration 06 — Rep metrics

## Status

Software complete on 2026-08-28. Tempo accuracy requires target-device validation.

## Depends on

Iteration 05.

## Goal

Capture reusable tempo and range evidence.

## Build

- Timestamp detector phases and store extrema/`RepMetrics`.
- Calculate squat range, outward/return/total duration, completion confidence.
- Invalidate or exclude sustained low-confidence gaps.

## Exit

- Deterministic samples produce correct non-negative durations and measured range.
- Missing bilateral data is unavailable, never zero.

## Cut

No charts or aggregate UI.
