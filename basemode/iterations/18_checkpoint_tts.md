# Iteration 18 — Checkpoint TTS

## Depends on

Iterations 13–17.

## Build

- Format pre-set, one deduplicated midpoint, post-set messages.
- Use target-rep midpoint; define explicit fallback when target absent.
- Reuse structured feedback and valid same-exercise history.
- Keep speech outside inference path.

## Exit

- No fabricated issue, history, or improvement.
- No rep-by-rep speech.
- Midpoint fires at most once.
- Good performance produces positive/neutral evidence.

## Cut

Reuse installed TTS/audio path. No generative service.

## Completed — 2026-08-29

- Added Open, 8, 10, and 12-rep set plans during preparation.
- Targeted midpoint uses `ceil(target / 2)`; Open sets explicitly use Rep 5.
- Added deterministic pre-set, one-shot midpoint, and post-set formatters using structured evidence only.
- Pre-set speech reads latest same-exercise durable or in-workout set; absent history uses neutral language.
- Mid-set correction requires the same structured issue at least twice; otherwise speech stays positive or neutral.
- Post-set speech uses reps, supported scores, degradation point, and repeated issues only.
- Removed rep-by-rep TTS from live tracking while preserving visible coaching and deduplicated haptics.
- Speech remains asynchronous and outside pose inference.
- Verification: `flutter analyze`, 159 tests, and debug APK build passed.
- Hardware pending: confirm speech timing, interruption, volume, and checkpoint audibility during real sets.
