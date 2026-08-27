# Right Posture — Progress

Last updated: 2026-08-27

This file is the first stop for every development session. Read it before opening the wider project. Update it after each completed iteration, important decision, or newly discovered blocker.

## Current phase

Iteration 08A software complete. Live directional coaching, optional persisted TTS/haptics, conservative degradation thresholds, and display-only skeleton smoothing are implemented; hardware validation remains pending.

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
- [x] Iteration 03: joint-angle math, squat rep state machine, calibration baseline, persistence evaluation, and session summary.
- [x] Iteration 04: production camera/detector ownership, app-owned pose mapping, pipeline states, lifecycle guards, and tests.
- [x] Iteration 05: Riverpod session lifecycle, live sample wiring, bottom-angle capture, summary, error recovery, and tests.
- [x] Iteration 06: responsive, accessible Exercise Select, Live Session HUD, and Session Summary flow.
- [x] Iteration 08A: phase-aware coaching, persisted TTS/haptics, conservative degradation tuning, and display-only skeleton smoothing.

## Not implemented

- Actual iQOO hardware compatibility and performance are unverified.
- Measured on-device inference latency was previously reported around 304 ms; Iteration 06 removes recurring UI animation and isolates camera-frame rebuilds, but only device tuning can verify improvement.

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
9. [`execution/08a_live_coaching.md`](execution/08a_live_coaching.md)
10. [`execution/09_demo_release.md`](execution/09_demo_release.md)

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
| 02 Camera/pose spike | Software complete | Analyze clean; 10 tests pass; debug APK built | Hardware checklist delegated to user |
| 03 Domain engine | Complete | Analyze clean; 22 total tests pass; debug APK built | Reality Checker findings fixed |
| 04 Camera/pose pipeline | Software complete | Analyze clean; 32 tests pass; debug APK built | Hardware checklist delegated to user |
| 05 Session state | Complete | Analyze clean; 37 tests pass; debug APK built | Test Results Analyzer: PASS |
| 06 Core UI flow | Software complete | Analyze clean; 43 tests pass; debug APK built | Hardware flow delegated to user |
| 07 Live integration/tuning | Device-gated | Analyze clean; 43 tests pass; debug APK built | Real-person calibration and performance measurements pending |
| 08 Resilience/polish | Software complete | Analyze clean; 47 tests pass; debug APK built | Hardware resilience checks pending |
| 08A Live coaching | Software complete | Analyze clean; 65 tests pass; debug APK built | TTS/haptics/latency hardware checks pending |
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
- `flutter test`: 10 rotation, coordinate-transform, and camera-selection tests passed.
- `flutter build apk --debug`: passed in 47.2s.
- Review agents used: AI Engineer and Test Automation Engineer.
- Hardware unverified: permission behavior, NV21 output on target phone, overlay alignment/cropping, latency, lifecycle, and 2-minute stability.
- User owns hardware checklist in `execution/02_device_pose_spike.md`.
- Next software iteration: Iteration 03 pure Dart domain engine.

## Iteration 02 alignment fix — 2026-08-27

- Root cause: pose painter used naïve scaling independent from camera preview rotation and layout.
- Overlay now renders inside `CameraPreview.child`, so preview and painter share exact bounds.
- Pose coordinates now account for ML Kit frame rotation and lens direction.
- Added an accessible front/back switch that selects the opposite lens directly, avoiding multiple-rear-camera traps.
- Added asymmetric coordinate-transform and camera-selection tests after UI Designer and Test Results Analyzer review.
- `flutter analyze`: passed, no issues.
- `flutter test`: 10 tests passed.
- `flutter build apk --debug`: passed in 14.8s.
- Hardware still required to confirm device-specific preview alignment and mirroring.

## Iteration 03 record — 2026-08-27

- Added finite-safe three-point joint-angle calculation.
- Added standing → bottom → standing squat state machine with hysteresis and confidence gating.
- Added configurable per-joint absolute ranges, deviation thresholds, 3-rep median calibration, and 2-rep persistence.
- Calibration reps use neutral `calibrating` status and are excluded from Form Score.
- Absolute-range violations after calibration become immediately `degraded`.
- Low-confidence or incomplete completed-rep samples do not affect rep number, baseline, or evaluation.
- Summary reports total reps, nullable Form Score, first degraded rep, primary responsible joint, and ordered checklist.
- `flutter analyze`: passed, no issues.
- `flutter test`: 22 total tests passed, including 12 domain-engine tests.
- `flutter build apk --debug`: final build passed in 5.8s.
- Review agents used: Mobile App Builder and Test Results Analyzer.
- Post-implementation Reality Checker found non-finite input and mutability gaps; both were fixed and reverified.
- Calibration-vs-immediate-absolute wording was aligned with approved behavior: first 3 reps stay neutral; immediate absolute degradation starts after calibration.
- Existing camera-selection and pose-transform changes/tests were preserved and also passed.
- Next iteration: Iteration 04 production camera/pose pipeline extraction and landmark-to-domain mapping.

## Iteration 04 record — 2026-08-27

- Extracted camera and ML Kit detector ownership into `PosePipeline`; camera screen now renders snapshots and forwards lifecycle actions.
- Added immutable app-owned overlay landmarks and squat knee-angle samples.
- Chooses the left/right leg with higher minimum hip-knee-ankle confidence; low-confidence/missing samples never reach domain logic.
- Added explicit initializing, ready, no-person, low-confidence, and failed states.
- Added generation guards, serialized start/pause/resume/close operations, dropped concurrent frames, awaited active processing before disposal, and retry.
- Three consecutive frame-processing failures now surface a truthful failed state instead of leaving stale ready output.
- Frame timing/count diagnostics are debug-only.
- Centralized rotation, mirroring, centered cover scaling, and crop offsets in the painter transform.
- Added mapper, pipeline-state widget, async single-flight, crop, and rotated-front tests.
- `flutter analyze`: passed, no issues.
- `flutter test`: 32 tests passed.
- `flutter build apk --debug`: final build passed in 16.7s.
- Reality Checker found and verified a pause/resume-during-initialization race fix; exact lifecycle ordering now has a regression test.
- Review agents used: AI Engineer, Test Results Analyzer, and Reality Checker.
- Hardware unverified: actual camera format, overlay alignment, switching, latency, permission flow, pause/resume, and stability.
- Next iteration: Iteration 05 Riverpod session state and live-sample-to-rep wiring.

## Iteration 05 record — 2026-08-27

- Added `flutter_riverpod 3.4.2` and root `ProviderScope`.
- Added one `NotifierProvider` holding selected exercise, phase, immutable reps, baseline, latest feedback, summary, and recoverable error.
- Added explicit start, end, reset, failure, and retry commands.
- Connected each new app-owned pipeline squat sample to the session controller without giving Riverpod camera ownership.
- Squat detector now returns the minimum knee angle reached at the bottom when a full standing → bottom → standing rep completes.
- Repeated standing, bottom, and return frames record exactly one rep.
- Ending freezes evaluation and derives summary; reset recreates detector/evaluator and clears all state.
- `flutter analyze`: passed, no issues.
- `flutter test`: 37 tests passed.
- `flutter build apk --debug`: passed in 28.6s.
- Review agent used: Test Results Analyzer; verdict PASS.
- Expected boundary: Iteration 06 must add UI calls for start/end/reset before live reps become visible.
- Next iteration: Iteration 06 core UI flow.

## Iteration 06 record — 2026-08-27

- Added a token-based dark Material theme using the locked lime, surface, warning, and degraded palette.
- Added the squat-only Exercise Select page and wired Start to Riverpod session state.
- Added a full-screen camera session with rep count, calibration/tracking verdict, reason, camera switch, retry, and End Set.
- Added a scrollable Session Summary with nullable Form Score, total reps, degradation callout, ordered checklist, and Restart.
- Added semantic labels/live camera initialization status, text/icon status cues, 48dp-plus controls, SafeArea usage, and constrained large-screen widths.
- Camera/skeleton content is excluded from accessibility noise; raw-frame updates rebuild only the camera surface, not the Riverpod HUD.
- No recurring live animations were added because inference latency is the current UX bottleneck.
- Fixed a real 320px/200% text-scale overflow by making Exercise Select scrollable.
- `flutter analyze`: passed, no issues.
- Accessibility post-audit findings were fixed: tracking loss replaces stale verdicts, important state changes use a live region, and the Live HUD scrolls under compact/large-text constraints.
- `flutter test`: 43 tests passed, including 6 core UI tests.
- `flutter build apk --debug`: final rebuild passed in 16.6s.
- Review agents used: UI Designer and Accessibility Auditor.
- Hardware unverified: real camera-to-summary flow, TalkBack, overlay alignment, thermal stability, and latency.
- Next iteration: Iteration 07 live integration and device tuning; user owns its hardware checks.

## Iteration 07 software checkpoint — 2026-08-27

- Confirmed existing debug telemetry exposes processed frames, last inference time, selected knee angle, side, and confidence.
- Confirmed camera pipeline already uses `ResolutionPreset.low`, base ML Kit pose model, and single-flight frame dropping.
- Fixed missing telemetry test import discovered after the latest repository commit.
- Kept confidence, standing, bottom, absolute-range, deviation, and persistence thresholds unchanged because no real-person dataset is available.
- `flutter analyze`: passed, no issues.
- `flutter test`: 43 tests passed.
- `flutter build apk --debug`: passed in 35.4s.
- Performance Benchmarker verdict: no software blocker; no latency improvement can be claimed without device data.
- Required hardware evidence: 3 scripted sets, rep accuracy, brief occlusion, leave-frame pause, median/p95 inference latency, approximate processed FPS, thermals, distance, angle, and lighting.

## Iteration 08 record — 2026-08-27

- Added explicit permission-denied, camera, and processing failure classification.
- Camera permission denial now explains recovery and offers Open settings plus Try again.
- Added a dependency-free Android channel opening this app's system settings page.
- Terminal failures hide the live HUD so recovery actions remain reachable.
- Failure recovery is scrollable and tested at 320×640 with 200% text scaling.
- Existing initialization retry, no-person, low-confidence, serialized lifecycle, and session recovery paths remain intact.
- Cut onboarding, animations, audio, and haptics under the iteration cut rule; latency remains higher priority.
- `flutter analyze`: passed, no issues.
- `flutter test`: 47 tests passed.
- `flutter build apk --debug`: passed in 26.9s.
- Review agent used: Mobile App Builder; compact failure overlap finding fixed and reverified.
- Hardware pending: deny/grant/settings return, background/foreground, repeated start/end/restart, and preview/pose performance.

## Iteration 08A record — 2026-08-27

- Added phase-aware prompts for standing setup, descent, valid depth, return, and excessive depth.
- Replaced generic deviation reasons with directional coaching: go lower or reduce depth.
- Increased provisional baseline deviation tolerance from 12° to 20° and persistence from 2 to 3 consecutive evaluated reps to reduce false degradation.
- Added `flutter_edge_tts 0.0.2` plus `audioplayers 6.8.1`; fixed prompts are prepared outside camera processing.
- TTS is serialized, deduplicated, latest-wins, limited by a 2-second cooldown, and cancelled on tracking loss. Visible text remains authoritative when online speech fails.
- Added native Flutter haptics for valid depth, warning, and degradation with transition deduplication.
- Added persisted Voice coaching and Haptic coaching settings, both enabled by default, using `shared_preferences 2.5.5`.
- Added compact two-line coaching UI with reduced-motion-aware fade/scale transition.
- Added display-only landmark smoothing and 50 ms interpolation. Raw landmarks still drive angles, rep detection, and evaluation; low-confidence/tracking-loss states disable interpolation.
- Session boundary now rejects landmark confidence below 0.6 even if called outside the pipeline.
- `flutter analyze`: passed, no issues.
- `flutter test`: 65 tests passed.
- `flutter build apk --debug`: passed in 23.5s.
- Review agents used: AI Engineer and Test Results Analyzer; both final verdicts PASS for software scope.
- Hardware pending: Edge TTS network timing/fallback, audio playback, physical haptics, perceived skeleton lag/render cost, real-person rep accuracy, and final threshold tuning.
