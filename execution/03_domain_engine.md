# Iteration 03 — Pure Dart Domain Engine

## Goal

Build and prove rep/evaluation logic without camera, Flutter widgets, or Riverpod.

## Scope

- Add minimal immutable models for exercise thresholds, joint samples, reps, session state, and summary.
- Implement three-point joint-angle calculation with invalid/degenerate-input handling.
- Implement squat standing/bottom/standing state machine with hysteresis to avoid double counts.
- Accept completed-rep angle samples, confidence-gate them, and establish median baseline from 3 valid reps.
- Evaluate absolute range and baseline deviation with consecutive-rep persistence.
- Derive Form Score, degradation start rep, responsible joint, and checklist.
- Keep thresholds as simple data constants so real-device tuning changes data, not algorithms.

## Tests

- Known 90° and 180° angle fixtures within tolerance.
- Noise near state boundary does not double-count.
- Partial movement does not count.
- Invalid/low-confidence sample does not affect rep count or baseline.
- Baseline median resists one outlier.
- One deviation gives warning; configured persistence gives degraded.
- Absolute violation follows approved immediate-verdict rule.
- Empty and calibration-only summaries avoid division by zero or misleading scores.

## Exit gate

All pure Dart tests pass. Domain engine imports no camera, ML Kit, Riverpod, or widget libraries.

