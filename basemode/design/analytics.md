# Analytics UI

## Purpose

Show movement-quality history without mixing exercises or implying unsupported improvement.

## Layout

- Analytics Home: exercise filter, recent evidence summary, activity calendar, weekly totals.
- Exercise Analytics: trend cards for available metrics, issue frequency, quality distribution, records.
- Day Journal: chronological sessions for selected local day.
- Session Entry: set comparison, rep timeline, issues, feedback history, metrics, optional note.

## Visual rules

- Use `fl_chart` for trend lines, quality distributions, weekly comparisons, and other data visuals.
- One primary metric per chart; label unit and exercise.
- Keep each card focused: one question, one chart, one short evidence summary. Avoid combined multi-axis charts.
- Limit visible series to one by default and two only for direct same-exercise comparisons.
- Use restrained grid lines, few readable axis labels, highlighted selected points, and tooltips with value, unit, and date/set context.
- Missing values are gaps. One point is a value, not a trend.
- Pair charts with concise text and screen-reader semantics.
- Use color plus labels/shapes for rep quality.
- Keep streak secondary to movement-quality evidence.
- Support 320 px width, 200% text scale, reduced motion.
- Disable or simplify chart animation when reduced motion is requested.

## Empty/error states

- No history: completed sessions create analytics.
- Insufficient comparison: show current value and `Not enough data for a trend`.
- Storage error: preserve live workout path and offer retry.

## Explicitly absent

Cross-exercise raw-angle ranking, predictive scores, generated clinical advice, social leaderboard, cloud history, camera playback.
