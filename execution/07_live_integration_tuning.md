# Iteration 07 — Live Integration and Threshold Tuning

## Status

Instrumented and device-gated as of 2026-08-27. Debug builds already expose processing time, knee angle, selected side, and landmark confidence. Camera input already uses `ResolutionPreset.low`. Threshold changes require hardware evidence.

## Goal

Make squat counting and degradation detection reliable for rehearsed real-person demo conditions.

## Scope

- Capture diagnostic angle/confidence values during scripted squat sets.
- Tune confidence threshold, standing/bottom thresholds, hysteresis, absolute range, deviation threshold, and persistence count.
- Validate across at least two people if time permits.
- Verify 3 calibration reps followed by good reps and 2 deliberately degraded reps produces expected checklist.
- Fix only observed failure modes; do not generalize into a universal biomechanics engine.

## Checks

- 3 complete scripted sets with expected rep counts.
- One brief occlusion/noisy sample does not create degraded status.
- Person leaving frame pauses evaluation.
- 6–8+ rep demo shows calibration then sustained degradation.
- Record tested distance, camera angle, lighting, and final thresholds in `progress.md`.

## Exit gate

Team has one reproducible demo setup and script. Any unsupported posture/body/camera limitations are documented honestly.

This gate is not met without real-person/device runs.
