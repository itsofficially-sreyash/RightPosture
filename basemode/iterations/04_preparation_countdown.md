# Iteration 04 — Preparation and countdown

## Status

Software complete on 2026-08-28. Stable placement automatically starts the countdown; pose loss resets it to 3. Three-frame stability and edge-margin behavior require target-device validation.

Device correction: countdown tolerates one unusable inference frame, then cancels after the second consecutive failure. Lifecycle/camera interruptions still cancel immediately.

## Depends on

Iteration 03.

## Goal

Start tracking only from usable camera placement.

## Build

- Add preparing, countdown, tracking, complete stages.
- Show profile guidance and missing-region feedback.
- Require stable mandatory landmarks.
- Add cancellable 3-2-1 countdown.

## Exit

- Preparation/countdown records no rep or baseline data.
- Countdown cancels on back, pause, exercise change, or sustained pose loss.
- Squat guidance works at 320 px and 200% text scale.

## Cut

Other exercise copy ships with each exercise slice.
