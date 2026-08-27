# Iteration 09 — Demo Release

## Goal

Produce tested Android artifact and repeatable 3–5 minute judge demo.

## Scope

- Run formatter, analyzer, tests, and release build.
- Install clean build on iQOO and verify permission-first launch.
- Rehearse Office Kit screen mirroring.
- Write exact demo script: select squat, 3 calibration reps, good reps, sustained degraded reps, end set, explain summary, restart.
- Rehearse full flow at least twice before Evaluation Round 1 and once before final demo.
- Remove debug overlays/log noise and verify no injury-risk or NPU claims remain.
- Record artifact path, commit, device/build versions, checks, and known limitations in `progress.md`.

## Release checks

- Clean install and cold launch.
- Camera permission deny/retry/grant.
- 2-minute live run.
- Expected count/status/summary for scripted set.
- Restart and second set.
- Offline operation.

## Exit gate

Release artifact and demo script both pass on actual device. No P2 work begins before this gate.

