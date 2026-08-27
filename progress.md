# Right Posture — Progress

Last updated: 2026-08-27

This file is the first stop for every development session. Read it before opening the wider project. Update it after each completed iteration, important decision, or newly discovered blocker.

## Current phase

Iteration 02 software integration complete. Physical camera/pose verification is user-owned and still pending.

## Completed

- [x] Product scope documented in `basemode/`.
- [x] MVP reduced to one evaluation pipeline with no user-facing modes.
- [x] Product language changed from unsupported injury-risk claims to form degradation.
- [x] Flutter project scaffold created in `mobile/`.
- [x] Initial UI direction, color tokens, screens, data shapes, error cases, and test priorities documented.
- [x] Repository re-read from current disk state on 2026-08-27.
- [x] Execution split into small, approval-gated iteration plans in `execution/`.
- [x] Iteration 01: Flutter/Android baseline, dependencies, permissions, docs, analyzer, and debug APK.
- [x] Iteration 02 software gate: camera stream, ML Kit input conversion, pose overlay, diagnostics, lifecycle handling, tests, and APK build.

## Not implemented

- App is still Flutter's `Hello World` shell.
- Camera, ML Kit pose detection, Riverpod, domain logic, UI screens, and tests are not implemented.
- Camera/pose behavior is not implemented yet; dependencies are installed only.
- Actual iQOO hardware compatibility and performance are unverified.

## Approved scope snapshot

- Target: Android/iQOO hackathon demo; iOS/desktop polish is out of scope.
- Core flow: Exercise Select → Live Session → Session Summary.
- Onboarding is P1 and cuttable.
- Squat is the first exercise. Lunge is P2, added only after squat works.
- One on-device pipeline: camera → ML Kit landmarks → joint angles → rep state machine → baseline/persistence evaluation → summary.
- No backend, accounts, cross-session persistence, clinical claims, or real physio integration.
- Office Kit use is screen mirroring, not an app subsystem.

## Decisions needed before implementation

- [x] Execution plans and iteration order approved on 2026-08-27.
- [x] Set ends through an explicit **End Set** button.
- [x] Squat-only initial delivery; lunge remains stretch scope.
- [x] Absolute-range violation produces immediate `degraded` verdict.
- [x] First 3 valid reps calibrate baseline and are excluded from Form Score.
- [ ] Replace placeholder Android ID `com.example.right_posture` before release; no organization/reverse-domain value is available yet.

## Known risks

- ML Kit package/device compatibility is the first hard gate; no fallback is selected.
- Exact landmark confidence, squat phase, absolute-angle, and baseline-deviation thresholds require real-device tuning.
- Camera image rotation, front/back-camera mirroring, and overlay coordinate transforms must be verified on device.
- Existing docs reference an `execution/` directory that did not exist before this planning pass.
- `.codex/agents/` contains 43 specialist agent configs. All were cataloged; relevant specialists are used at development/test gates. Unrelated roles are not given invented work.

## Execution index

1. [`execution/01_project_baseline.md`](execution/01_project_baseline.md)
2. [`execution/02_device_pose_spike.md`](execution/02_device_pose_spike.md)
3. [`execution/03_domain_engine.md`](execution/03_domain_engine.md)
4. [`execution/04_camera_pose_pipeline.md`](execution/04_camera_pose_pipeline.md)
5. [`execution/05_session_state.md`](execution/05_session_state.md)
6. [`execution/06_core_ui_flow.md`](execution/06_core_ui_flow.md)
7. [`execution/07_live_integration_tuning.md`](execution/07_live_integration_tuning.md)
8. [`execution/08_resilience_polish.md`](execution/08_resilience_polish.md)
9. [`execution/09_demo_release.md`](execution/09_demo_release.md)

## Resume protocol

1. Read this file.
2. Read only the current iteration file and files it links.
3. Check `git status` before edits; preserve unrelated user work.
4. Load required global and project-local skills. If local skill files remain absent, record that here.
5. Implement only the current iteration.
6. Run its exit checks.
7. Update this file with files changed, checks run, results, decisions, and next iteration.
8. Generate a Conventional Commit message summarizing the completed iteration; do not create the commit unless explicitly requested.
9. Stop at any explicit approval or hardware gate.

## Iteration log

| Iteration | Status | Evidence | Notes |
|---|---|---|---|
| 01 Project baseline | Complete | Analyze clean; debug APK built | No tests exist yet; Riverpod deferred until Iteration 05 |
| 02 Camera/pose spike | Software complete | Analyze clean; 3 tests pass; debug APK built | Hardware checklist delegated to user |
| 03 Domain engine | Pending | — | Pure Dart, deterministic tests |
| 04 Camera/pose pipeline | Pending | — | Depends on iteration 02 |
| 05 Session state | Pending | — | Depends on domain engine |
| 06 Core UI flow | Pending | — | P0 screens first |
| 07 Live integration/tuning | Pending | — | Real-person/device calibration |
| 08 Resilience/polish | Pending | — | P1 only after stable P0 |
| 09 Demo release | Pending | — | Rehearsal and release artifact |

## Iteration 01 record — 2026-08-27

- Toolchain: Flutter `3.48.0-0.3.pre` on main, Dart `3.13.0-138.0.dev`, Android SDK 36, JDK 17.
- Connected devices: Linux desktop only. No iQOO detected during `flutter devices`; ADB recheck was not approved.
- Added `camera 0.12.0+2` and `google_mlkit_pose_detection 0.16.1`.
- Deferred `flutter_riverpod` until Iteration 05 because Iterations 02–04 do not use it.
- Android minimum SDK set to 24; camera permission and required-camera feature declared.
- Orientation remains unlocked, matching responsive-layout requirements.
- `flutter analyze`: passed, no issues.
- `flutter test`: no `test/` directory, expected until Iteration 03.
- `flutter build apk --debug`: passed in 348.9s.
- Artifact: `mobile/build/app/outputs/flutter-apk/app-debug.apk` (186 MB debug build).
- Review agents used: Mobile App Builder and Rapid Prototyper.

## Iteration 02 record — 2026-08-27

- Replaced Hello World with a minimal live camera/pose diagnostic screen.
- Android requests single-plane NV21 frames; ML Kit uses base streaming detector.
- Sensor/device/lens rotation compensation follows installed ML Kit package guidance.
- Frame callback uses a synchronous busy flag, dropping frames while detection runs.
- Added lime skeleton overlay plus pose/frame/processing-time diagnostics.
- Added camera lifecycle cleanup/resume, error state, and retry.
- `flutter analyze`: passed, no issues.
- `flutter test`: 3 rotation-compensation tests passed.
- `flutter build apk --debug`: passed in 47.2s.
- Review agents used: AI Engineer and Test Automation Engineer.
- Hardware unverified: permission behavior, NV21 output on target phone, overlay alignment/cropping, latency, lifecycle, and 2-minute stability.
- User owns hardware checklist in `execution/02_device_pose_spike.md`.
- Next software iteration: Iteration 03 pure Dart domain engine.
