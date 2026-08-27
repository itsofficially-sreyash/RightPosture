# Iteration 01 — Project Baseline

## Goal

Make the Flutter shell reproducible and ready for the device spike without building product features.

## Scope

- Confirm installed Flutter/Dart/Android tool versions and available devices.
- Run current analyzer and default tests; record baseline failures.
- Confirm Android application ID, minimum SDK, camera permission requirements, and supported orientation policy.
- Add only packages used by the next iteration: `camera` and `google_mlkit_pose_detection`. Defer `flutter_riverpod` until Iteration 05.
- Replace placeholder README with exact local run/test commands and iQOO setup notes.

## Not in scope

- App architecture scaffolding, screens, pose math, thresholds, lunge, or visual polish.

## Checks

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- Debug Android build succeeds.

## Exit gate

Dependency resolution and empty app build succeed. Record exact versions and commands in `progress.md`. The release application ID may remain open until an organization/reverse-domain value is supplied.
