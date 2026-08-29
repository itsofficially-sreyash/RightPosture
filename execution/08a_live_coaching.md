# Iteration 08A — Live Squat Coaching

## Status

Software complete on 2026-08-27. Hardware validation remains pending for online TTS timing, physical haptics, perceived skeleton lag, rendering cost, and final thresholds.

## Problem

Post-calibration reps are frequently marked degraded because the current baseline deviation tolerance is 12 degrees and persistence requires only two consecutive deviations. Feedback arrives after a rep and describes a threshold failure without telling the user how to correct the next movement. The pose skeleton also visibly trails movement because it represents the latest completed ML Kit inference.

## Goal

Reduce false degradation and provide short, phase-aware on-screen correction prompts while retaining the visible skeleton.

## Behavior

- Waiting at standing: `Ready — squat down`.
- Descending before valid depth: `Go lower`.
- Valid bottom depth: `Depth good — stand up`.
- Excessive depth: `Too deep — come up slightly`.
- Returning from the bottom: `Stand up`.
- Missing or low-confidence landmarks continue to override coaching with existing framing guidance.
- Completed deviations use directional feedback:
  - Bottom angle above baseline tolerance: `Next rep: go slightly lower`.
  - Bottom angle below baseline tolerance: `Next rep: do not go as deep`.
- Coaching remains visible as text even if speech synthesis or playback fails.
- Coaching text uses a compact dark translucent chip above the bottom HUD, limited to two lines and kept out of the body-center region.

## User settings

- Add a Settings page opened from a labeled gear button on Exercise Select.
- Expose only two switches:
  - Voice coaching, enabled by default. Explain that synthesis requires internet.
  - Haptic coaching, enabled by default.
- Persist both values with `shared_preferences ^2.5.5` using its async API.
- Load preferences before showing the main flow. If loading fails, use the documented defaults and keep the app usable.
- Apply settings to the next/live session without opening a settings modal over the camera.
- Animation, smoothing, interpolation, and skeleton visibility are fixed implementation behavior, not user settings in this iteration.

## Provisional thresholds

- Baseline deviation tolerance: 20 degrees instead of 12 degrees.
- Persistence: 3 consecutive evaluated reps instead of 2.
- Existing standing, bottom, confidence, and absolute-range values remain unchanged.
- These values are demo defaults, not biomechanical or clinical claims. Device testing may revise them.

## Architecture

- Expose the squat detector's movement phase as an app-owned enum.
- Derive coaching from phase plus current knee angle in pure Dart.
- Store current coaching in `SessionState` and update it from each accepted high-confidence sample.
- Render coaching in the existing live HUD.
- Add `flutter_edge_tts ^0.0.2` for online synthesis and `audioplayers ^6.8.1` for playback.
- Pre-synthesize the fixed prompt set outside camera-frame processing. Speech failure never blocks detection or changes visible coaching.
- Speak only when guidance changes, with a two-second cooldown and no overlapping playback.
- Use Flutter `HapticFeedback` without another package. Trigger only on valid depth, completed warning, or completed degradation.
- Add a short `AnimatedSwitcher` coaching transition and a small status pulse. Disable both when `MediaQuery.disableAnimations` is true.
- Apply exponential smoothing to display landmarks only. Domain angles, rep detection, and evaluation continue using raw ML Kit coordinates.
- Interpolate the visible skeleton between the two latest display snapshots over at most 50 ms. Stop interpolation when tracking is lost or confidence fails.
- Keep the skeleton visible. Smoothing/interpolation targets jitter only and must not be described as eliminating inference latency.

## Files

- `mobile/lib/domain/squat_rep_detector.dart`: public phase and pure guidance.
- `mobile/lib/domain/models.dart`: coaching enum/value if needed.
- `mobile/lib/domain/rep_evaluator.dart`: directional deviation reasons.
- `mobile/lib/session_controller.dart`: live coaching state and provisional threshold changes.
- `mobile/lib/pose_camera_page.dart`: coaching text in existing HUD.
- `mobile/lib/coaching_cues.dart`: deduplicated TTS/playback/haptic side effects, isolated from frame processing.
- `mobile/lib/pose_painter.dart`: display-only smoothing/interpolation inputs.
- `mobile/lib/settings_controller.dart`: persisted TTS/haptic preferences and defaults.
- `mobile/lib/ui/settings_page.dart`: two accessible persisted switches.
- `mobile/lib/ui/exercise_select_page.dart`: labeled Settings entry.
- `mobile/pubspec.yaml`: `flutter_edge_tts ^0.0.2`, `audioplayers ^6.8.1`, and `shared_preferences ^2.5.5`.
- Existing domain, session, and UI test files.
- `progress.md`: results and hardware caveats.

## Tests

- Standing, descending, valid depth, excessive depth, and return prompts.
- Low-confidence samples do not advance phase or replace framing guidance.
- 20-degree tolerance boundaries remain good.
- First and second consecutive deviations warn; third degrades.
- Directional completed-rep reason is correct above and below baseline.
- Live HUD displays coaching without compact-width or 200% text overflow.
- TTS deduplicates repeated prompts, obeys cooldown, and degrades silently to text.
- Haptics fire only for selected state transitions.
- TTS and haptic settings default on, persist across controller recreation/app restart, and can be independently disabled.
- Settings labels, switch semantics, compact width, and 200% text scaling pass.
- Coaching chip stays within two lines and outside the main body-center area.
- Reduced-motion mode removes coaching animation.
- Display smoothing does not modify domain knee angles.
- Interpolation never runs after tracking loss and remains capped at 50 ms.
- Full analyzer, test suite, and debug APK build.

## Cuts

- No voice selection UI, downloaded voice catalog UI, SSML controls, persistent audio cache, new exercise, or background audio.
- No network or audio work inside camera-frame processing.
- No claim that skeleton latency is fixed. Hardware profiling remains required; interpolation is removed if it worsens perceived lag.

## Exit gate

Automated coaching, cue throttling, smoothing boundaries, and threshold behavior pass. Hardware validation must confirm prompt timing, network fallback, haptics, rep accuracy, visible skeleton acceptability, added rendering cost, and final thresholds.
