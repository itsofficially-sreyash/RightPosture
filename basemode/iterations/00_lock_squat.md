# Iteration 00 — Lock current squat behavior

## Status

Complete on 2026-08-28. Software regression gate passed; physical-device behavior remains unchanged and unverified.

## Goal

Create regression baseline before generalization.

## Build

- Repair/add deterministic tests for squat counting, calibration, persistence, summary scoring, and tracking loss.
- Record current device behavior without changing product behavior.

## Touch

Existing squat detector, evaluator, controller tests; `progress.md`.

## Exit

- Scripted sequence counts exactly once per rep.
- Calibration reps do not affect score.
- Tracking loss cannot create or finish a rep.
- Analyzer and relevant tests pass.

## Cut

No production refactor. Record hardware findings; do not guess around them.
