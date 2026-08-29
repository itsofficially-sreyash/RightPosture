# State management

Riverpod remains the app state boundary. Camera/ML ownership stays outside widgets and outside persistent history.

## Providers/controllers

- Settings: independently persisted voice, degraded-rep sound, and degraded-rep haptic preferences.
- Session controller: selected profile, optional set target, session stage, detector/evaluator/smoother lifecycle, reps, baseline, feedback, summary.
- Workout controller: immutable completed sets, next set, change exercise, finish/reset workout.
- History repository/provider: versioned summary JSON load/save through `shared_preferences`.
- Analytics providers: pure derived filters/aggregates by exercise, day, week, and selected session.

## Boundaries

- Pose mapper creates domain-safe coordinates/confidence.
- Metric extraction calculates angles/normalized distances.
- Detector owns attempt phases/completion.
- Evaluator owns baseline, thresholds, issues, persistence, verdict.
- Feedback selector formats evidence.
- Checkpoint formatter derives pre/mid/post speech; midpoint state deduplicates once per set.
- Cue coordinator deduplicates degraded events by set identity plus rep number and suppresses background output.
- Summary/analytics code aggregates immutable summaries.
- Widgets render state and invoke actions only.

## Reset rules

- Next Set preserves workout/history and exercise; clears live detector, smoothing, calibration, feedback, countdown.
- Change Exercise preserves workout/history; loads new profile and clears live engines.
- Finish Workout persists one immutable summary snapshot.
- Reset Workout clears current in-memory workout, not durable history.

## Explicit no's

No mode provider, raw camera state in analytics, Riverpod code generation, database abstraction, backend, account, or cross-exercise raw-metric comparison.
