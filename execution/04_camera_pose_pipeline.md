# Iteration 04 — Camera/Pose Pipeline

## Goal

Turn spike findings into smallest reusable production pipeline.

## Scope

- Extract camera lifecycle and pose-detector ownership from spike code.
- Convert ML Kit landmarks into app-owned joint samples needed by squat logic only.
- Centralize confidence gating, image rotation, mirroring, and coordinate transforms.
- Expose current preview/pose state to UI with clear states: initializing, ready, no person, low confidence, and failed.
- Keep single-flight frame processing and deterministic resource disposal.
- Remove temporary spike diagnostics unless still useful for tuning behind a debug flag.

## Tests

- Unit-test coordinate conversion and selected-landmark mapping where possible.
- Widget smoke test for each pipeline state using fake app-owned samples, not platform camera mocks.
- Re-run 2-minute iQOO test after extraction.

## Exit gate

Production pipeline matches spike performance and has no product screen coupling.

