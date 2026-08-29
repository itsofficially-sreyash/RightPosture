# Iteration 20 — Release hardening

## Depends on

All features intended for release.

## Build

- Run analyzer, full tests, Android build, accessibility, lifecycle, error, privacy, performance checks.
- Run three scripted sets per visible exercise plus degraded-set rehearsal.
- Verify history retention, chart accessibility, TTS/cue timing, corrupt-data fallback.
- Tune profiles only from recorded device evidence.

## Exit

- Every visible exercise passes device gate.
- Failed exercise/analytics feature stays hidden.
- No camera data persists or leaves device.
- Known limits/final thresholds recorded in `progress.md`.

## Cut

Cut cosmetics before tracking stability, evidence integrity, accessibility, or privacy.
