# Iteration 14 — Local history foundation

## Status

Software complete on 2026-08-28. History is local, versioned, bounded to 100 workouts, and contains summary evidence only.

## Depends on

Iteration 13.

## Goal

Persist minimum data needed for day/week analytics and journals.

## Build

- Store versioned JSON workout summaries with installed `shared_preferences`.
- Persist exercise, timestamp, sets, outcomes, component scores, ROM/tempo aggregates, degradation point, issues, feedback, optional note.
- Add bounded retention and corrupt/unknown-version fallback.
- Persist guided-demo visit flags in same store.

## Exit

- History survives restart and groups by local day/exercise.
- No frame, landmarks, image, or raw pose sample is stored.
- Corrupt history cannot block exercise flow.

## Cut

No DB, migration framework, account, cloud, sync, or attachments. Add DB only after measured failure.

## Software evidence

- Added one versioned JSON document using installed `shared_preferences`; no dependency or DB added.
- Persists exercise, local timestamp, outcomes, component scores, ROM/tempo/symmetry/consistency aggregates, degradation point, structured issues, delivered feedback, optional note, and guided-demo visit flags.
- Retention keeps newest 100 workouts.
- Corrupt JSON, corrupt records, and unknown versions return usable empty/partial history and never block workout flow.
- Helpers group by device-local day and filter sets by exercise without mixing metrics.
- Serialization regression proves no frame, image, landmark, pose sample, or raw angle map is retained.
- `flutter analyze`: no issues.
- `flutter test`: 136 tests passed.
- Debug APK built successfully.
