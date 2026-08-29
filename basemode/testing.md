# Testing

Each iteration owns its smallest deterministic checks. Full suite remains required at release hardening.

## Domain gates

- Confidence, smoothing reset, side lock, partial attempts, detector phase boundaries.
- Baseline/persistence, structured issue priority, missing metrics, summary scoring.
- One normal and noisy/partial/tracking-loss sequence per exercise.

## State and storage gates

- Exactly one immutable snapshot per completed set/workout.
- Correct next-set/change-exercise/reset behavior.
- Versioned JSON round-trip, bounded retention, corrupt/unknown-version fallback.
- No persisted frame, image, landmark stream, or raw pose sample fields.

## Analytics gates

- Grouping by exercise and local day/week.
- Missing values remain gaps.
- Trends require comparable same-exercise data.
- Improvement/record/feedback claims link to supporting sessions.
- One session, ties, and unavailable data use neutral output.

## Widget/accessibility gates

- Exercise cards, preparation/countdown, live HUD, summaries, history filters, calendar, charts, and journal entry.
- 320 px width, 200% text scale, semantics, reduced motion, and color-independent status.

## Physical device

Three scripted sets per exposed exercise plus one degraded set. Record device, camera, orientation, distance, lighting, expected/actual count, latency, and final thresholds. Hardware gate cannot be replaced by automated tests.
