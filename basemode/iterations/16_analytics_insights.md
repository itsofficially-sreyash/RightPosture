# Iteration 16 — Analytics insights

## Depends on

Iteration 15.

## Build

- Improvement Areas and Recent Progress Summary.
- Best Set / Best Session and Personal Records.
- Feedback History with later same-metric comparison.
- Secondary workout streak.
- Weekly strongest/weakest exercise using normalized scores, never raw angles.

## Evidence rules

- Comparable same-exercise metrics and minimum sample count required.
- Use improved, declined, unchanged tolerance bands.
- Never invent missing history, cause, issue, or clinical meaning.

## Exit

- Every insight links to supporting sessions/metrics.
- One session cannot produce trend claim.
- Ties/unavailable data use neutral language.

## Cut

Pure Dart comparisons only. No LLM, prediction model, or opaque score.

## Completed — 2026-08-29

- Added same-exercise recent comparisons for Form Score, consistency, degradation point, and symmetry with explicit tolerance bands.
- Kept ROM and raw tempo out of improvement claims because direction alone does not prove better form.
- Added traceable best set/session, personal records, repeated-feedback follow-up, latest activity streak, and weekly exercise ranking.
- Every comparison shows earlier/later values and opens both supporting session entries.
- Ties, missing metrics, one-session history, and fewer than two weekly exercises use neutral language.
- Weekly ranking uses only available normalized Form Score and consistency percentages.
- Verification: `flutter analyze`, 148 tests, and debug APK build passed.
