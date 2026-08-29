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
- User-owned hardware check: run 2-minute Android/iQOO test after extraction when a device is available.

## Exit gate

Analyzer, automated tests, and Android build pass. Production pipeline has no product screen coupling. Hardware performance remains explicitly unverified until the user reports results.
