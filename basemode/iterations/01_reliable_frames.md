# Iteration 01 — Reliable squat frames

## Status

Software complete on 2026-08-28. Target-device smoothing responsiveness and side visibility remain hardware checks.

## Depends on

Iteration 00.

## Goal

Prevent noise, low confidence, and side changes from corrupting squat data.

## Build

- Propagate landmark and derived metric confidence.
- Gate mandatory metrics at configured threshold.
- Lock tracked side during each attempt.
- Add one small per-metric smoother; reset on tracking/session/camera changes.

## Spec

Merged spec sections 1.1, 1.3, 1.4.

## Exit

- Low-confidence frames cannot start/finish reps or calibration.
- One noisy frame cannot create a rep.
- Side stays stable during active attempt.
- Smoothing never crosses rep/session boundaries.

## Cut

Squat only. No exercise registry.
