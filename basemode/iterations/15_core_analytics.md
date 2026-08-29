# Iteration 15 — Core analytics

## Depends on

Iteration 14.

## Build

- Add `fl_chart` at this iteration, not earlier.
- Exercise-wise history.
- Day journal and activity calendar.
- Per-exercise Form Score, ROM, tempo, degradation-point, symmetry, consistency trends.
- Issue frequency, rep quality distribution, weekly summary.
- Session detail with sets, timeline, issues, feedback, metrics, note editing.

## Exit

- Exercises never share raw metric series.
- Missing metrics create gaps, not zeros.
- Day grouping uses local date.
- No-data and one-point states remain honest.

## Cut

Use `fl_chart` with small focused cards. No multi-axis chart, 3D effect, dense legend, or custom chart framework. Fall back to text/table summaries when a chart cannot remain accessible at compact sizes.

## Completed — 2026-08-29

- Added exercise-filtered history, weekly evidence, local-day activity journal, and session drill-down.
- Added focused Form Score, ROM, tempo, degradation-point, symmetry, and consistency cards with explicit units.
- Added issue-frequency bars and labelled rep-quality distribution.
- Missing samples split trend lines; one sample remains a value, not a claimed trend.
- Persisted per-rep status/issues/feedback and editable session notes without frames, landmarks, or raw angles.
- Added reduced-motion handling, chart semantics, and compact/200% text coverage.
- Verification: `flutter analyze`, 141 tests, and debug APK build passed.
