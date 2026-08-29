# Iteration 03 — Shared exercise contracts

## Status

Software complete on 2026-08-28. Squat uses shared contracts; unfinished registry entries remain unavailable.

## Depends on

Iteration 02.

## Goal

Move unchanged squat behavior behind smallest reusable domain boundary.

## Build

- Add `ExerciseId`, `MovementMetric`, `MovementFrame`, `ExerciseProfile`, and `RepDetector`.
- Add direct `switch`-based registry.
- Port squat without visible behavior change.

## Exit

- Squat uses shared contracts.
- Iterations 00–02 tests still pass.
- Widgets contain no movement-quality calculations.
- Android app keeps screen awake while foregrounded.

## Cut

No code generation or factory framework.
