# Right Posture — Progress

Last updated: 2026-08-28

This file is the first stop for every development session. Read it before opening the wider project. Update it after each completed iteration, important decision, or newly discovered blocker.

## Current phase

Expansion Iteration 14 is software complete. Finished workouts now persist as bounded, versioned local summary evidence. Iterations 10–11 remain deferred.

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
- Core flow: Exercise Select → Guided Demo/Setup → Live Session → Set/Workout Summary → local History/Analytics.
- Onboarding is P1 and cuttable.
- Exercises: Squat, Bicep Curl, Lateral Raise, Shoulder Press, Reverse Lunge, Jumping Jack; each remains hidden until its full gate passes.
- One on-device pipeline: camera → ML Kit landmarks → joint angles → rep state machine → baseline/persistence evaluation → summary.
- Local bounded summary persistence supports journals/analytics. No backend, accounts, cloud sync, retained pose/image data, clinical claims, or real physio integration.
- Office Kit use is screen mirroring, not an app subsystem.

## Decisions needed before implementation

- [x] Execution plans and iteration order approved on 2026-08-27.
- [x] Set ends through an explicit **End Set** button.
- [x] Squat-only initial delivery; lunge remains stretch scope.
- [x] Absolute-range violation produces immediate `degraded` verdict.
- [x] First 3 valid reps calibrate baseline and are excluded from Form Score.
- [x] Expansion scope and 21 low-context iteration files approved on 2026-08-28.
- [x] Analytics uses versioned summary JSON through installed `shared_preferences`; no DB until measured need.
- [x] Expansion Iteration 00 regression lock completed on 2026-08-28.
- [x] Expansion Iteration 01 reliable-frame software gate completed on 2026-08-28.
- [x] Expansion Iteration 02 partial-attempt software gate completed on 2026-08-28.
- [x] Expansion Iteration 03 shared-contract software gate completed on 2026-08-28.
- [x] Android app-wide keep-awake enabled with native window flag; no dependency added.
- [x] Expansion Iteration 04 preparation/countdown software gate completed on 2026-08-28.
- [x] Expansion Iteration 05 structured-feedback software gate completed on 2026-08-28.
- [x] Expansion Iteration 06 rep-metrics software gate completed on 2026-08-28.
- [x] Expansion Iteration 07 bicep-curl software gate completed on 2026-08-28.
- [x] Expansion Iteration 08 lateral-raise software gate completed on 2026-08-28.
- [x] Expansion Iteration 09 shoulder-press software gate completed on 2026-08-28.
- [x] Expansion Iteration 12 detailed-set-summary gate completed on 2026-08-28.
- [x] Expansion Iteration 13 workout-comparison gate completed on 2026-08-28.
- [x] Expansion Iteration 14 local-history foundation completed on 2026-08-28.
- [ ] Expansion Iterations 10–11 deferred by user; return after post-summary/analytics work.
- [ ] Replace placeholder Android ID `com.example.right_posture` before release; no organization/reverse-domain value is available yet.

## Known risks

- ML Kit package/device compatibility is the first hard gate; no fallback is selected.
- Exact landmark confidence, squat phase, absolute-angle, and baseline-deviation thresholds require real-device tuning.
- Camera image rotation, front/back-camera mirroring, and overlay coordinate transforms must be verified on device.
- Existing docs reference an `execution/` directory that did not exist before this planning pass.
- `.codex/agents/` contains 43 specialist agent configs. All were cataloged; relevant specialists are used at development/test gates. Unrelated roles are not given invented work.

## Execution index

Expansion work uses [`basemode/iterations.md`](basemode/iterations.md) and its 21 standalone files. Current software checkpoint: [`basemode/iterations/14_local_history.md`](basemode/iterations/14_local_history.md).

Legacy implementation plans:

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
| Expansion 00 Squat regression lock | Complete | Analyze clean; 67 tests pass | Two focused session regression tests added; no production changes |
| Expansion 01 Reliable squat frames | Software complete | Analyze clean; 72 tests pass | Hardware responsiveness and side visibility pending |
| Expansion 02 Partial squat attempts | Software complete | Analyze clean; 75 tests pass | Attempt thresholds need device tuning |
| Expansion 03 Shared exercise contracts | Software complete | Analyze clean; 78 tests pass; debug APK built | Only squat registry entry enabled |
| Expansion 04 Preparation/countdown | Software complete | Analyze clean; 82 tests pass | Three-frame stability needs device timing check |
| Expansion 05 Structured feedback | Software complete | Analyze clean; 87 tests pass | Copy and thresholds need device validation |
| Expansion 06 Rep metrics | Software complete | Analyze clean; 91 tests pass | Tempo accuracy needs device validation |
| Expansion 07 Bicep curl | Software complete, device-gated | Analyze clean; 108 tests pass; debug APK built | Adaptive skeleton stability/latency and three curl sets required |
| Expansion 08 Lateral raise | Software complete, device-gated | Analyze clean; 117 tests pass; debug APK built | Three target-device sets required; release card remains hidden |
| Expansion 09 Shoulder press | Software complete, device-gated | Analyze clean; 124 tests pass; debug APK built | Three target-device sets required; release card remains hidden |
| Expansion 10–11 Exercises | Deferred | — | Return after summary/analytics work |
| Expansion 12 Detailed set summary | Software complete | Analyze clean; 126 tests pass; debug APK built | Lightweight widgets; no chart dependency |
| Expansion 13 Workout comparison | Software complete | Analyze clean; 130 tests pass; debug APK built | Memory-only; persistence begins in Iteration 14 |
| Expansion 14 Local history | Software complete | Analyze clean; 136 tests pass; debug APK built | Version 1 JSON; newest 100 workouts retained |

## Expansion Iteration 00 record — 2026-08-28

- Added a five-rep scripted squat regression proving one ordered result per completed movement and calibration status on first three reps.
- Added a low-confidence mid-attempt regression proving tracking loss cannot finish a rep.
- Existing detector/evaluator tests already cover boundary noise, partial movement, calibration median, persistence, summary scoring, and missing confidence.
- Production code unchanged.
- `dart format lib test`: passed, 0 files changed.
- `flutter analyze`: passed, no issues.
- `flutter test`: 67 tests passed.
- Hardware behavior remains unverified; Iteration 00 did not tune thresholds or claim device results.
- Next: `basemode/iterations/01_reliable_frames.md`.

## Expansion Iteration 01 record — 2026-08-28

- Added dependency-free rolling median smoothing with a three-frame window.
- Metric confidence remains the minimum confidence of hip, knee, and ankle; explicit regression added.
- Session boundary rejects confidence below `0.6`, resets active detector/smoother/side state, and preserves completed reps/baseline.
- Selected side locks through the active rep and unlocks only after completion or tracking interruption.
- Camera switch, lifecycle pause, no-person, low-confidence, and pipeline failure reset tracking input.
- Smoothing resets after every rep and tracking/session/camera boundary, so values never cross boundaries.
- `flutter analyze`: passed, no issues.
- `flutter test`: 72 tests passed.
- Hardware pending: perceived three-frame smoothing delay, side visibility under occlusion, rep accuracy, and thresholds.
- Next: `basemode/iterations/02_partial_attempts.md`.

## Expansion Iteration 02 record — 2026-08-28

- Added permissive movement start at `10°` excursion and deliberate-attempt minimum at `25°`; both configurable demo thresholds.
- Detector tracks standing angle, minimum knee angle, excursion, movement direction, and incomplete-attempt count.
- A rep completes only after returning to standing with enough excursion.
- Deliberate shallow squat reaches evaluator and receives `Next rep: go lower`; standing jitter and abandoned attempts do not increment reps.
- Completion exposes start/minimum extrema; session evaluator consumes measured minimum knee angle.
- Coaching remains direction-aware during shallow descent and return.
- `flutter analyze`: passed, no issues.
- `flutter test`: 75 tests passed.
- Hardware pending: tune `10°`/`25°`, test slow/fast shallow reps, and verify no venue-noise false counts.
- Next: `basemode/iterations/03_shared_contracts.md`.

## Expansion Iteration 03 record — 2026-08-28

- Added `ExerciseId`, `MovementMetric`, `MovementFrame`, `ExerciseProfile`, `RepCompletion`, `RepDetector`, camera-view, body-joint, and tracked-side contracts.
- Added direct switch registry; only Squat resolves. Unfinished exercises throw and remain unavailable.
- `SessionState.selectedExercise` now uses `ExerciseId`.
- Squat receives smoothed value/confidence/side through `MovementFrame`; evaluator consumes generic completion extrema.
- Existing squat adapter remains for focused tests; visible behavior unchanged.
- Android `MainActivity` applies `FLAG_KEEP_SCREEN_ON` without a package.
- First analyzer run hit a dev-SDK segmentation fault; immediate retry passed.
- `flutter analyze`: passed, no issues.
- `flutter test`: 78 tests passed.
- `flutter build apk --debug`: passed; native Android change compiled.
- Next: `basemode/iterations/04_preparation_countdown.md`.

## Expansion Iteration 04 record — 2026-08-28

- Added preparing and countdown session stages; Exercise Select now enters preparation instead of tracking.
- Squat placement requires one confident shoulder/hip/knee/ankle side and rejects landmarks within a 5% image-edge margin.
- Placement messages distinguish step into frame, show required joints, move farther back, and ready.
- Three consecutive ready processed frames enable Start Set; starting runs cancellable 3-2-1 countdown.
- Pose frames cannot reach detector/evaluator during preparation or countdown.
- Pose loss, camera switch, lifecycle pause, Back/reset, and controller disposal cancel countdown/reset preparation.
- Stable placement automatically starts the countdown; any pose loss requires a fresh stable lock and restarts at 3.
- Added scrollable, token-based preparation HUD with semantics and compact 320 px/200% text test.
- Flutter UI/responsive skill kept content constrained, scrollable, semantic, and free from orientation/device-type assumptions.
- `flutter analyze`: passed, no issues.
- `flutter test`: 82 tests passed.
- Hardware pending: confirm three processed frames approximate one stable second at real inference rate and validate 5% edge margin.
- Next: `basemode/iterations/05_structured_feedback.md`.

## Expansion Iteration 05 record — 2026-08-28

- Replaced evaluator-owned feedback strings with structured `RepIssue` evidence: exercise, metric, direction, measured value, optional baseline, and normalized severity.
- Added deterministic issue priority and squat copy catalog with safe human-language fallback.
- Live HUD, coaching cues, accessibility semantics, and summaries now derive text from structured issues; internal metric identifiers stay hidden.
- Tracking interruption and pipeline failure clear stale feedback.
- `flutter analyze`: passed, no issues.
- `flutter test`: 87 tests passed.
- Hardware pending: validate copy timing and evaluator thresholds during real squat sets.
- Next: `basemode/iterations/06_rep_metrics.md`.

## Expansion Iteration 06 record — 2026-08-28

- Added immutable `RepMetrics` to shared completions and evaluated reps.
- Squat records measured knee excursion, outward/return/total duration, and minimum completion confidence.
- Missing bilateral timing remains `null`; no fabricated zero value.
- Low-confidence shared frames reset the active detector, preventing gaps from inflating tempo.
- Out-of-order timestamps clamp durations to zero, never negative.
- `flutter analyze`: passed, no issues.
- `flutter test`: 91 tests passed.
- Hardware pending: validate real processed-frame timing and confidence interruptions.
- Next: `basemode/iterations/07_bicep_curl.md`.

## Expansion Iteration 07 record — 2026-08-28

- Added front-view bilateral shoulder-elbow-wrist mapping and placement guidance.
- Added simultaneous curl detector requiring extension-curl-extension and both-arm return.
- Captures per-arm extrema, ROM, tempo, minimum confidence, and peak timing difference.
- Partial curls reach evaluator; standing duplicates and low-confidence gaps do not count.
- Added curl-specific range and symmetry feedback through shared structured issues.
- Added normalized torso-position evidence; squat-like vertical translation resets curl attempts.
- Moved the debug curl preview below the primary Squat card.
- Stabilized skeleton display without changing detector inputs: primary pose only, `0.6` landmark confidence gate, adaptive EMA, and reset on tracking loss.
- Medium resolution produced frequent 15–39 MB large-object GC collections and 1–2 second perceived delay on target device; reverted to low resolution.
- Replaced fixed display EMA with adaptive smoothing (`0.2` stationary, `0.7` moving) so jitter is damped without multi-frame motion lag.
- Removed hardcoded Squat text from shared preparation, settings, and debug diagnostics.
- Countdown requires two consecutive unusable placement frames before resetting, avoiding cancellation from one inference glitch.
- Debug builds expose Bicep Curl as a device-tuning preview; release builds keep card hidden.
- Controller test covers four reps through calibration, evaluation, and summary.
- `flutter analyze`: passed, no issues.
- `flutter test`: 108 tests passed.
- `flutter build apk --debug`: passed.
- Device gate: three scripted target-device sets must count correctly before release exposure and Iteration 08.

## Expansion Iteration 08 record — 2026-08-28

- Added lateral-raise profile, bilateral pose mapping, detector, session wiring, structured feedback, diagnostics, and debug-only selection card.
- Both arms must raise and return; low confidence or excessive torso movement invalidates active attempt.
- Rep evidence includes bilateral elevation range, elbow bend, timing symmetry, duration, and confidence.
- Shared preparation HUD reads exercise profile content. Squat, curl, and lateral raise use one automatic countdown and three-rep calibration engine.
- Added regressions for detector behavior, registry exposure, correct card/content, shared countdown, calibration, and compact exercise selection.
- `flutter analyze`: passed, no issues.
- `flutter test`: 117 tests passed.
- `flutter build apk --debug`: passed.
- Device gate: three scripted target-device lateral-raise sets must count correctly before release exposure.

## Expansion Iteration 09 record — 2026-08-28

- Added Shoulder Press profile, bilateral detector, registry entry, shared session wiring, feedback, diagnostics, and debug-only card.
- Press starts and ends with both hands near shoulder height; both hands must return before completion.
- Tracks overhead elevation, elbow extension, bilateral timing, torso stability, ROM, tempo, and confidence.
- Incomplete overhead movement remains a completed attempt and receives `Press both hands fully overhead` feedback.
- Shared setup content, automatic countdown, pose-loss reset, and three-rep calibration include Shoulder Press.
- `flutter analyze`: passed, no issues.
- `flutter test`: 124 tests passed.
- `flutter build apk --debug`: passed.
- Device gate: three scripted target-device Shoulder Press sets must count correctly before release exposure.

## Expansion Iteration 12 record — 2026-08-28

- Skipped Iterations 10–11 by user direction; no reverse-lunge or jumping-jack work added.
- Extended summaries with weighted Form Score, component scores, consistency, averages, best/lowest rep, and quality distribution.
- Calibration and missing metrics do not lower component scores. Fewer than two evaluated reps produces no Form Score.
- Added exercise-aware score labels and tappable horizontal rep timeline with accessible movement details.
- Timeline remains usable at 320 px and 200% text scaling.
- Flutter UI skill guided token reuse, extracted widgets, semantics, 48 dp controls, and responsive scrolling.
- `flutter analyze`: passed, no issues.
- `flutter test`: 126 tests passed.
- `flutter build apk --debug`: passed.

## Expansion Iteration 13 record — 2026-08-28

- Added immutable completed-set snapshots and in-memory workout state without image, frame, landmark, or raw pose retention.
- End Set appends exactly once. Next Set resets all live/calibration state while preserving exercise and workout history.
- Change Exercise preserves history. Finish Workout opens grouped totals and same-exercise comparisons. New Workout clears history explicitly.
- Workout summary shows reps, Form Score, average ROM/tempo, degradation point, consistency, and issue count per set.
- Raw movement metrics are compared only inside same-exercise groups; mixed exercises receive totals only.
- Flutter UI skill guided extracted cards, scrollable layouts, design tokens, empty state, and accessible controls.
- `flutter analyze`: passed, no issues.
- `flutter test`: 130 tests passed.
- `flutter build apk --debug`: passed.

## Expansion Iteration 14 record — 2026-08-28

- Added versioned, bounded local workout history using installed `shared_preferences`; no DB or new dependency.
- Stores summary evidence required for journals/analytics: exercise/timestamp, outcomes, components, ROM/tempo/symmetry/consistency aggregates, degradation point, issues, feedback, optional note, and demo visits.
- Retains newest 100 workouts. Corrupt JSON, corrupt records, unknown versions, and platform storage failures cannot block live/workout flow.
- Added device-local day grouping and exercise filtering helpers.
- Storage tests assert serialized JSON contains no frames, images, landmarks, pose samples, or raw angle maps.
- `flutter analyze`: passed, no issues.
- `flutter test`: 136 tests passed.
- `flutter build apk --debug`: passed.

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

## Iteration 15 record — 2026-08-29

- Added `fl_chart 1.2.0` for small, single-metric analytics cards.
- Added exercise-wise history, seven-day summaries, local-day journal, and detailed saved-session entries.
- Added Form Score, ROM, tempo, degradation-point, symmetry, and consistency trends without mixing exercises.
- Added issue frequency and labelled good/warning/degraded rep distribution.
- Missing values remain gaps; a single value explicitly says it is insufficient for a trend.
- Persisted rep outcomes and editable notes while continuing to exclude frames, images, landmarks, and raw angles.
- Added focused domain, persistence, empty-state, and 320px/200%-text analytics tests.
- `flutter test`: 141 tests passed.
- Iterations 09–11 remain intentionally deferred as previously agreed.

## Iteration 16 record — 2026-08-29

- Added a pure Dart, same-exercise insight engine; no LLM, prediction, opaque score, or dependency.
- Recent progress compares the latest two comparable values with metric-specific tolerance bands.
- Improvement claims are limited to Form Score, consistency, later degradation, lower symmetry error, and reduced same-issue rate.
- Added Best Set, Best Session, supported Personal Records, repeated Feedback History follow-up, latest activity streak, and normalized weekly strongest/weakest exercise.
- Earlier/later evidence buttons open both supporting saved sessions.
- Ties, insufficient samples, missing metrics, and unavailable weekly comparisons stay neutral.
- `flutter analyze`: passed with no issues.
- `flutter test`: 148 tests passed.
- Iterations 09–11 remain intentionally deferred as previously agreed.

## Iteration 17 record — 2026-08-29

- Added per-exercise first-visit Guided Demo gating using the existing versioned local history store.
- Added five automatic, 2-second-spaced posture/instruction cycles requiring fresh ready pose frames.
- Pose loss, low confidence, stale frames, and unsupported exercise metrics do not advance demo progress.
- Added exercise-aware knee, elbow, bilateral elevation, and symmetry guidance for implemented exercises only.
- Existing voice setting controls spoken demo guidance; visual guidance stays authoritative on synthesis failure.
- Added compact per-card Replay Demo actions; normal later visits skip completed demos.
- Demo exit marks nothing, and failed persistence never blocks regular preparation/countdown.
- `flutter analyze`: passed with no issues.
- `flutter test`: 153 tests passed.
- `flutter build apk --debug`: passed.
- Hardware pending: real-person five-cycle timing, exercise-specific setup thresholds, camera switching, and spoken guidance.
- Iterations 09–11 remain intentionally deferred as previously agreed.

## Iteration 18 record — 2026-08-29

- Added Open, 8, 10, and 12-rep set plans; selected targets survive preparation and countdown.
- Targeted midpoint is `ceil(target / 2)`; Open sets visibly define Rep 5 as fallback.
- Added deterministic pre-set, single midpoint, and post-set TTS formatters using structured evidence only.
- Pre-set speech filters durable and in-workout evidence to the selected exercise.
- Mid-set correction requires a repeated matching issue; good or insufficient evidence stays positive/neutral.
- Post-set speech reports only supported reps, scores, degradation point, and repeated issue correction.
- Removed live rep-by-rep TTS while retaining visible coaching and haptic transitions.
- Speech synthesis/playback remains asynchronous outside pose processing.
- `flutter analyze`: passed with no issues.
- `flutter test`: 159 tests passed.
- `flutter build apk --debug`: passed.
- Hardware pending: speech timing, interruptions, volume, and audibility during real sets.
- Iterations 09–11 remain intentionally deferred as previously agreed.

## Iteration 19 record — 2026-08-29

- Added one heavy haptic and one short Flutter system alert for every completed degraded rep.
- Added independent persisted Sound cues control beside Voice coaching and Haptic coaching.
- Warning, good, calibration, depth, and tracking-loss states remain visual and produce no degraded cue.
- Deduplication uses exercise/set identity plus rep number; rebuilds cannot replay and consecutive degraded reps cue independently.
- Disabled or backgrounded degraded events are consumed silently and cannot replay after enabling or resuming.
- Lifecycle pause suppresses channels and interrupts pending audio; output remains outside pose inference.
- Reused Flutter `SystemSound`; no package, asset, or exercise-specific sound was added.
- `flutter analyze`: passed with no issues.
- `flutter test`: 161 tests passed.
- `flutter build apk --debug`: passed.
- Hardware pending: alert volume, vibration strength, lifecycle suppression, and consecutive degraded-rep behavior.
- Iterations 09–11 remain intentionally deferred as previously agreed.
