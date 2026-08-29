# Product requirements

`rightposture_merged_spec.md` is the final behavior specification. `iterations.md` is the canonical build order.

## Problem

People exercising alone can see a rep count but often cannot tell whether visible movement range, tempo, symmetry, or consistency changed during a set. RightPosture provides on-device, evidence-based coaching from 2D pose landmarks. It does not diagnose injury or replace a coach or clinician.

## Users

Primary user: a gym or home-workout user performing a supported standing exercise in view of one phone camera.

## Supported exercises

Squat, Reverse Lunge, Bicep Curl, Shoulder Press, Lateral Raise, and Jumping Jack. Availability is gated per exercise; unfinished exercises stay hidden.

## Core loop

1. Select an available exercise.
2. Complete first-visit guidance when applicable.
3. Follow camera placement guidance and countdown.
4. Perform a planned set while the app counts and evaluates reps.
5. Receive concise live feedback and one optional midpoint spoken cue.
6. Review set summary, timeline, scores, and optional spoken summary.
7. Start another set, change exercise, or finish the in-memory workout.
8. Review local exercise history, journal entries, and evidence-based trends after summary persistence ships.

## Success criteria

- Every visible exercise counts three scripted device sets correctly.
- Low-confidence data, jitter, or brief occlusion cannot silently create a good rep.
- Partial deliberate reps are evaluated for range instead of disappearing.
- Feedback uses only measured metrics, configured thresholds, and valid same-exercise history.
- Calibration and unavailable metrics never lower Form Score.
- Camera frames never leave the device or enter workout history.
- UI remains usable at 320 px width and 200% text scaling.

## Out of scope

- Injury diagnosis, prediction, treatment, or clinical claims.
- Accounts, cloud sync, backend, cross-device history, or retained camera/landmark data.
- Multi-person tracking.
- Direct comparison of raw metrics across different exercises.
- Push-ups, planks, deadlifts, floor exercises, calorie estimates, or trainer/clinic integration.

## Main risks

- 2D monocular pose cannot measure depth reliably.
- Landmark quality varies with lighting, distance, clothing, and occlusion.
- Thresholds require target-device tuning across multiple people.
- TTS and UI work must never block inference.

Mitigation and release gates live in `iterations.md`, `testing.md`, and `error_handling.md`.
