# Iteration 02 — Partial squat attempts

## Status

Software complete on 2026-08-28. Attempt/excursion thresholds require target-device tuning.

## Depends on

Iteration 01.

## Goal

Count deliberate shallow attempts, then judge achieved range separately.

## Build

- Add permissive movement start, minimum excursion, extrema tracking, and return-to-start completion.
- Keep abandoned attempts separate from completed reps.
- Pass extrema to evaluator.

## Spec

Merged spec section 1.2.

## Exit

- Deliberate shallow squat completes and receives range feedback.
- Standing jitter does not count.
- Abandoned attempt does not inflate rep count.

## Cut

No new exercise or generic detector framework.
