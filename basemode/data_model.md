# Data model

Domain shapes are app-owned Dart models. Live state is in memory. Only bounded summary evidence is persisted.

## Exercise and movement

- `ExerciseId`: squat, reverseLunge, bicepCurl, shoulderPress, lateralRaise, jumpingJack.
- `MovementFrame`: timestamp, metric values, per-metric confidence, tracked side/mode.
- `ExerciseProfile`: required landmarks, phase metrics, thresholds, calibration count, persistence count, camera guidance.
- `RepCompletion`: attempt extrema, phase timestamps, side/mode, confidence.

## Rep

- number and status: calibrating, good, warning, degraded.
- structured `RepIssue` list; primary issue is derived, not separately inferred.
- `RepMetrics`: total/outward/return/optional transition duration, ROM map, optional bilateral timing difference, completion confidence.
- Calibration reps are excluded from scores. Missing metrics are unavailable, not zero.

## Live session

- selected exercise/profile, stage, reps, per-metric baseline, latest feedback/error, optional `SetPlan`.
- stages: idle, preparing, countdown, tracking, complete.
- Detector, smoother, calibration, countdown, and feedback deduplication reset between sets.

## Summaries

- `SessionSummary`: total/evaluated reps, Form Score, degradation start, component scores, averages, best/lowest rep, quality distribution, consistency score, timeline.
- `CompletedSet`: immutable set number, exercise, completion time, reps, summary.
- `WorkoutState`: completed sets plus current session.

## Persisted history

Versioned summary JSON contains:

- workout/session ID and local completion timestamp;
- exercise and immutable set summaries;
- rep outcomes, structured issues, delivered feedback;
- aggregate Form Score, ROM, tempo, symmetry, consistency, and degradation point where available;
- optional user-entered note;
- per-exercise guided-demo completion flag.

Never persist frames, images, landmark streams, or raw pose samples. Retention must be bounded. Unknown/corrupt versions fall back without blocking live sessions.

## Analytics derivation

Group history by `ExerciseId` before comparing movement metrics. Trend points retain missing values. Insights require comparable same-exercise samples and explicit tolerance/minimum-sample rules. User notes are context, not measured evidence.
