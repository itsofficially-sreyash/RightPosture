# tech_stack.md

## App
- Flutter (cross-platform, but demo target is the iQOO Android loaner — do not spend time on iOS polish).
- Riverpod for state management (see statemanagement.md).
- `camera` package for camera feed access.

## Pose detection / ML
- `google_mlkit_pose_detection` (locked in decision.md D3, flipped from `flutter_pose_detection`) — Google's production ML Kit Pose Detection API, BlazePose-based, Android + iOS.
  - Provides: 33-point pose landmarks (image-coordinate + confidence per landmark). Does NOT provide built-in angle/distance helpers — joint-angle math is hand-written (budgeted in execution/03_pose_engine.md, execution/04_rep_detection_core.md).
  - No documented Snapdragon NPU delegate control — do not claim NPU-specific acceleration in the pitch (decision.md D3).
  - No fallback package currently defined if this fails hardware verification — flag immediately if execution/01_verify_hardware.md fails, this needs a fresh decision.

## Local storage
- Live session/workout state stays in Riverpod memory.
- `shared_preferences` stores settings, guided-demo flags, and bounded versioned summary JSON for journals/analytics.
- No raw pose/image data. No DB unless measured history size or query performance requires one.

## Backend
- None planned for MVP. If Office Kit scoring requires a laptop-side companion view (see workflow.md, unresolved), decide the minimal version then — do not pre-build a backend speculatively.

## Build/tooling
- Standard Flutter toolchain (`flutter pub get`, `flutter run`).
- Native Android `FLAG_KEEP_SCREEN_ON`; no wakelock package.
- Test `google_mlkit_pose_detection` build + camera permission flow on the iQOO loaner FIRST in Green Light hours — this is the single highest-risk unknown in the whole stack (see decision.md D3, prd.md open risks).

## Explicitly not using
- No cloud AI API calls for pose detection — on-device only (this is the rubric-relevant claim, don't undermine it by secretly calling a cloud endpoint anywhere in the pipeline).
- No calorie/heart-rate sensor integration (feature rejected, see features.md).
