# More Features - Multi-Exercise Product and Implementation Specification

This document expands RightPosture from its current squat-only prototype into a six-exercise, on-device movement-coaching demo. It supplements `features.md`; it does not replace the existing MVP decisions.

The product claim remains limited to visible movement, range, tempo, consistency, and form degradation. RightPosture must not claim to diagnose injuries, predict injury risk, or replace a qualified coach or clinician.

## Feature package

1. Fix confidence propagation, partial-rep handling, side stability, and smoothing.
2. Add camera-position guidance and a start countdown.
3. Support six exercises through configurable multi-joint evaluation.
4. Produce human-friendly live feedback.
5. Measure tempo and range of motion.
6. Add a rep timeline and score breakdown to the summary.
7. Add multi-set comparison with in-memory workout history.
8. Add haptic/audio feedback for degraded reps.

## Supported exercises

The existing Squat remains the first and best-tuned exercise. Add five exercises chosen for visual clarity, repeatable rep phases, low equipment requirements, and ease of demonstration in a hackathon venue.

| Exercise | Suggested view | Main phase signal | Supporting measurements | Why it demos well |
|---|---|---|---|---|
| Squat | Slight side view | Knee flexion and return to standing | Hip flexion, torso lean, depth | Existing implementation and clear fatigue/depth story |
| Reverse lunge | Side or slight diagonal view | Lead-knee flexion and return to standing | Hip movement, torso lean, stance stability | Reuses lower-body landmarks while visibly differing from squat |
| Bicep curl | Front or slight diagonal view | Elbow flexion and extension | Upper-arm drift, left/right symmetry, tempo | Very reliable upper-body joint signal and easy live repetition |
| Shoulder press | Front view | Wrist/elbow movement from shoulder level to overhead | Elbow extension, wrist symmetry, torso lean | Clear start/end positions and visible overhead completion |
| Lateral raise | Front view | Wrist elevation from hip level to shoulder level | Elbow bend, left/right symmetry, torso lean | Simple standing setup and strong symmetry visualization |
| Jumping jack | Front full-body view | Feet and wrists move apart then return | Arm range, leg spread, left/right timing | Dynamic full-body finale that is immediately understandable to judges |

### Deliberately deferred exercises

Push-ups, planks, deadlifts, and floor exercises are deferred. They require different camera placement, increase occlusion risk, or lack a simple standing-to-standing rep loop. Exercise quality matters more than library size for the demo.

## Product flow

```text
Exercise Select
  -> Exercise Setup and Camera Guidance
  -> 3-2-1 Countdown
  -> Calibration Reps
  -> Live Multi-Joint Coaching
  -> Set Summary
  -> Next Set or Finish Workout
  -> Multi-Set Comparison
```

Every exercise uses this same flow. Exercise-specific behavior comes from configuration and a small detector strategy, not separate screens or duplicated session controllers.

## First-time guided exercise demo and TTS coaching flow

This behavior applies on top of the shared product flow above and must work consistently for every supported exercise.

### First-time guided demo for each exercise

The first time the user opens a particular exercise, the app should run a short guided demonstration/setup sequence before allowing the user to move directly into normal exercise sessions on later visits.

The sequence is:

1. Show the live camera feed and skeleton landmarks.
2. Ask the user to stand in the exercise-specific starting position.
3. Verify the user's posture using the available pose landmarks and exercise-specific metrics.
4. Give the first instruction.
5. Re-check the user's posture after the instruction.
6. Give the next instruction based on the newly observed posture.
7. Repeat this instruction -> posture check cycle for a total of 5 guidance iterations.
8. After the first guided visit for that exercise has been completed, future visits can proceed directly to the regular exercise flow unless the user explicitly chooses to view the demo again.

The guided sequence must remain exercise-aware. Instructions should be derived from metrics that the selected exercise can actually measure.

### TTS behavior during real exercise sessions

Do not use text-to-speech after every rep. Continuous TTS would be distracting and would make the live coaching experience noisy.

Instead, use TTS at specific checkpoints.

#### At the start of a set

If previous data exists for the same exercise, generate a short spoken summary using only measurements that are actually present in stored in-memory workout/session data.

The summary should cover:

- what still needs improvement, when supported by previous measurements;
- what has improved, when a valid previous comparison exists;
- the most important actionable correction for the upcoming set.

Do not invent history, problems, improvements, or measurements that are not present in the available data.

For example:

- Squat: `You are going too low in your squats. Try to keep your thighs closer to parallel.`
- Dumbbell/arm movement: `Your arm is reaching about 60 degrees; try to keep it closer to the 45-degree target.`

These are examples of understandable feedback style, not hard-coded claims. Actual spoken values and corrections must come from the selected exercise's measured metrics, thresholds, and previous-session data.

If the available previous data shows that the user performed well and there is no supported problem to mention, the TTS must not fabricate an earlier mistake merely to produce coaching.

If no previous data exists, use only the current setup/calibration context and do not pretend that the user has historical performance data.

#### Mid-set feedback

Analyze the completed reps continuously, but do not speak after each rep.

After approximately 50% of the planned total reps in the set have been completed, provide one concise TTS coaching message based on the data collected in the current set up to that point.

The message should prioritize:

1. the most important persistent form issue;
2. the strongest supported improvement opportunity;
3. a concise actionable instruction for the remaining reps.

If no meaningful issue is supported by the data, the message should remain positive or neutral and must not invent a correction.

The system needs the planned rep target for the set in order to determine the 50% checkpoint. If the set has no predefined rep target, the implementation must use an explicitly defined alternative checkpoint rather than pretending that 50% is known.

#### End-of-set TTS summary

At the end of the current set/session, provide a spoken summary in addition to the visual summary.

The spoken summary should use the current session's measured data and may include:

- total completed reps;
- Form Score or equivalent supported score;
- range-of-motion consistency;
- tempo consistency;
- symmetry where measurable;
- the first persistent degradation point, if one exists;
- the strongest issue observed;
- a supported improvement compared with previous same-exercise data, when available;
- one concise recommendation for the next set.

The TTS summary must follow the same evidence rules as the visual feedback:

- no clinical or injury-risk claims;
- no invented measurements;
- no fabricated history;
- no claim that something improved unless comparable previous data exists;
- no claim that something was wrong earlier if the data shows otherwise;
- do not expose raw internal metric identifiers in speech.

### TTS and feedback evidence rules

All generated spoken feedback must be grounded in structured session data such as `RepIssue`, `RepMetrics`, component scores, exercise thresholds, calibration baselines, and same-exercise workout history.

The TTS layer formats evidence; it does not independently infer movement quality.

Recommended architecture:

```text
Pose / MovementFrame
  -> Exercise Detector
  -> Shared Evaluator
  -> Structured RepIssue + RepMetrics
  -> Session / Workout Summary
  -> Feedback Selector
  -> Human-friendly text
  -> TTS
```

This keeps spoken feedback deterministic and prevents the speech layer from hallucinating unsupported problems or improvements.

Recommended additional state:

```dart
class ExerciseVisitState {
  final ExerciseId exercise;
  final bool hasCompletedGuidedDemo;
}

class SetPlan {
  final int? targetRepCount;
}

enum SpokenFeedbackCheckpoint {
  preSet,
  midSet,
  postSet,
}
```

`hasCompletedGuidedDemo` persists per exercise with the same local summary/settings store introduced for analytics. A failed visit-state read falls back safely to showing the demo; it never blocks exercise setup.

### Additional acceptance criteria

- The first visit to each exercise can run the five-step guided posture/instruction loop.
- A later visit to that exercise can skip the guided demo according to the implemented visit-state scope.
- Posture is checked between guidance instructions rather than giving five fixed instructions blindly.
- TTS is not triggered after every repetition.
- Pre-set TTS uses previous same-exercise data only when that data exists.
- Mid-set TTS triggers once at the defined halfway checkpoint and is deduplicated.
- End-of-set TTS summarizes only supported current-session and valid historical comparisons.
- Good performance does not generate fabricated negative feedback.
- Improvements are mentioned only when comparable earlier data supports them.
- Spoken angle/range examples use actual configured or measured values rather than invented numbers.
- TTS never blocks pose inference or rep detection.

## Architecture: shared engine plus exercise profiles

The current implementation is coupled to `SquatFrameSample` and `SquatRepDetector`. Generalization should introduce a shared measurement and detection contract.

```dart
enum ExerciseId {
  squat,
  reverseLunge,
  bicepCurl,
  shoulderPress,
  lateralRaise,
  jumpingJack,
}

enum MovementMetric {
  leftKneeAngle,
  rightKneeAngle,
  leftHipAngle,
  rightHipAngle,
  leftElbowAngle,
  rightElbowAngle,
  torsoLean,
  armElevation,
  stanceWidth,
  wristHeightSymmetry,
  ankleHeightSymmetry,
}

class ExerciseProfile {
  final ExerciseId id;
  final String displayName;
  final CameraView recommendedView;
  final Set<BodyJoint> requiredLandmarks;
  final Set<MovementMetric> phaseMetrics;
  final Map<MovementMetric, MetricThreshold> thresholds;
  final int calibrationRepCount;
  final int persistenceCount;
}

class MovementFrame {
  final DateTime timestamp;
  final Map<MovementMetric, double> values;
  final Map<MovementMetric, double> confidence;
  final TrackedSide trackedSide;
}

abstract interface class RepDetector {
  RepCompletion? addFrame(MovementFrame frame);
  void reset();
}
```

Recommended detector implementations:

- `SquatRepDetector`
- `ReverseLungeRepDetector`
- `BicepCurlRepDetector`
- `ShoulderPressRepDetector`
- `LateralRaiseRepDetector`
- `JumpingJackRepDetector`

Each detector owns only movement phases and rep completion. The shared evaluator owns baselines, absolute ranges, deviation persistence, issue severity, and final verdicts.

## 1. Measurement reliability

### Goal

Count a rep only when the movement is deliberate and the landmarks needed by the selected exercise are reliable. Noise, occlusion, side switching, or a partial movement must not silently become a good rep.

### 1.1 Propagate landmark confidence

Current issue: the pose mapper calculates confidence, but the session controller passes `confidenceOk: true` into the existing squat detector and evaluator.

Implementation:

- Keep confidence per landmark and derive confidence per metric from the least-confident landmark used by that metric.
- Each exercise profile declares mandatory phase metrics and optional evaluation metrics.
- Reject a frame for phase detection when a mandatory metric is below the configured minimum, initially `0.6`.
- Optional metrics may be absent without discarding an otherwise valid rep.
- Aggregate confidence across the rep, using a minimum or low percentile rather than the final frame alone.
- Do not increment rep number, calibration count, or persistence counters for an invalid completion.
- Show neutral `Tracking paused` guidance rather than a stale verdict.

### 1.2 Separate attempt detection from quality evaluation

Current issue: a shallow squat may never reach the detector's bottom threshold, so it is ignored instead of being counted and evaluated as shallow. The same problem would occur with incomplete curls, presses, raises, lunges, and jumping jacks.

Implementation:

- Use permissive movement-start thresholds to detect a deliberate attempt.
- Require a minimum excursion to reject standing jitter.
- Track extrema throughout the attempt.
- Complete a rep when the user returns to the exercise's start region.
- Pass the extrema to the evaluator, which decides whether the achieved range was good, warning, or degraded.
- Track incomplete attempts separately for optional coaching, but do not inflate completed-rep count.

Generic phase sequence:

```text
waitingForStart -> outward/concentric phase -> transition -> return/eccentric phase -> completed
```

Exercise interpretation:

- Squat/lunge: standing -> descending -> bottom -> standing.
- Curl: elbow extended -> flexing -> peak curl -> extended.
- Shoulder press: hands near shoulders -> pressing -> overhead -> hands near shoulders.
- Lateral raise: arms down -> raising -> shoulder height -> arms down.
- Jumping jack: closed stance -> opening -> open position -> closed stance.

### 1.3 Stable side and limb selection

- Squat and reverse lunge lock the best visible side for each rep.
- Bicep curl can operate as left, right, or simultaneous mode; default demo mode evaluates both visible arms and uses the weaker-confidence arm only when both are reliable.
- Shoulder press, lateral raise, and jumping jack use bilateral landmarks and must not silently collapse to a single side when symmetry is being scored.
- Lock selected sides for the duration of a rep.
- Switch only after the active side is poor for several frames and the alternative is consistently stronger.
- Reset smoothing when switching sides.
- Store the tracked side/mode on each rep for diagnostics.

Starting values to tune on device:

- confidence threshold: `0.6`
- side-switch persistence: 5 processed frames
- confidence advantage to switch: `0.1`

### 1.4 Angle and normalized-distance smoothing

- Apply a rolling median of 3-5 samples or a small exponential moving average before phase detection.
- Smooth each metric independently.
- Retain raw values only for debug diagnostics.
- Reset buffers when tracking is lost, the camera changes, the exercise changes, or a session resets.
- Never smooth values across different reps.
- Use body-normalized distances for metrics such as stance width so camera distance changes do not alter thresholds. For example, divide ankle separation by shoulder width or torso length.

### Tests and acceptance criteria

- Low-confidence mandatory metrics cannot start or complete reps.
- Missing optional metrics do not stop valid phase detection.
- One noisy frame cannot create a rep or a degraded result.
- Deliberate partial-range attempts are distinguished from standing jitter.
- Small confidence fluctuations do not alternate the tracked side.
- Bilateral exercises require usable landmarks on both sides for symmetry scoring.
- Every exercise completes exactly one rep for a deterministic start-peak-start sample sequence.
- Three physical-device sets per exercise produce the rehearsed rep count.

Likely files:

- `mobile/lib/pose_landmark_mapper.dart`
- `mobile/lib/session_controller.dart`
- `mobile/lib/domain/models.dart`
- `mobile/lib/domain/rep_detector.dart`
- `mobile/lib/domain/exercise_profile.dart`
- `mobile/lib/domain/angle_smoother.dart`
- `mobile/lib/domain/detectors/`

## 2. Exercise-aware camera guidance and countdown

### Goal

Help the user choose the correct view and fit required joints into the frame before calibration begins.

### Guidance by exercise

| Exercise | Guidance |
|---|---|
| Squat | Step back until shoulders, hips, knees, and ankles are visible; face sideways |
| Reverse lunge | Show the full body and leave space behind the stepping leg; use a slight side view |
| Bicep curl | Face the camera or turn slightly; keep shoulders, elbows, and wrists visible |
| Shoulder press | Face the camera; leave space above the head and keep wrists visible overhead |
| Lateral raise | Face the camera; leave space on both sides so wrists remain visible |
| Jumping jack | Face the camera; fit the full body with space above the head and beside both hands and feet |

### Experience

1. Show the live preview with a concise instruction card.
2. Identify missing required regions, for example `Move back - ankles are not visible`.
3. Require valid landmarks for approximately one second.
4. Enable `Start set` when placement is stable.
5. Show `3`, `2`, `1`, then begin calibration.

### Implementation

- Add session stages: `preparing`, `countdown`, `tracking`, and `complete`.
- Load required landmarks and guidance copy from `ExerciseProfile`.
- Run pose detection during preparation but do not feed frames into the detector or baseline.
- Add viewport-margin checks so a landmark close to an image edge can produce `Move farther back` before it disappears.
- Cancel countdown on Back, lifecycle pause, exercise change, or sustained pose loss.
- Use a cancellable timer protected by session generation/mounted checks.
- Keep camera orientation guidance explicit; do not auto-rotate exercise logic without tests.

### Acceptance criteria

- Each exercise displays its own positioning instructions.
- Tracking records no reps during preparation or countdown.
- Start becomes available only when mandatory landmarks are stable.
- Countdown runs exactly once and cancels safely.
- Instructions fit at 320 px width and 200% text scaling.

## 3. Exercise-specific multi-joint evaluation

### Shared measurement rules

- Calculate metrics from the same pose and timestamp.
- Use 2D image-coordinate geometry only; do not claim depth-camera accuracy.
- Store bottom/peak values plus rep-wide minima and maxima.
- Calibration calculates a median baseline independently for every available metric.
- Absolute-range violations detect incorrect range even during early use.
- Baseline deviation detects changes from the user's established movement.
- Persistent deviation promotes warning to degraded.
- If multiple metrics fail, choose the largest normalized deviation as the primary issue while retaining all issues.

### 3.1 Squat profile

Required landmarks: shoulder, hip, knee, and ankle on one stable side.

Metrics:

- knee flexion: hip -> knee -> ankle
- hip flexion: shoulder -> hip -> knee
- torso lean: shoulder-to-hip vector relative to image vertical
- knee range of motion
- optional left/right knee symmetry in front-view mode

Feedback candidates:

- `Go a little deeper`
- `Stand tall to finish the rep`
- `Keep your chest more upright`
- `Keep your depth consistent`

### 3.2 Reverse-lunge profile

Required landmarks: shoulders, hips, knees, and ankles; the detector identifies the leg that steps backward and treats the other as the lead leg.

Metrics:

- lead-knee flexion
- rear-knee flexion when visible
- lead-hip movement
- torso lean
- normalized step length
- return-to-balanced-stance symmetry

Detection considerations:

- Begin in a narrow standing stance.
- Detect one ankle moving backward relative to the body axis.
- Enter the bottom phase after sufficient lead-knee flexion.
- Complete when both ankles return near the start stance and the body is upright.
- Treat alternating legs as separate valid reps but store `leftLead` or `rightLead`.

Feedback candidates:

- `Take a slightly longer step back`
- `Lower a little more`
- `Keep your torso upright`
- `Return to a balanced stance`

### 3.3 Bicep-curl profile

Required landmarks: shoulder, elbow, and wrist for each evaluated arm.

Metrics:

- elbow angle
- elbow displacement relative to shoulder/torso
- upper-arm angle relative to torso
- left/right peak timing and range symmetry
- curl range of motion and tempo

Detection considerations:

- Start with elbow extended.
- Peak occurs at minimum elbow angle.
- Complete after returning to the extension region.
- For simultaneous curls, complete the rep only when both arms return; store per-arm metrics.

Feedback candidates:

- `Curl through a little more range`
- `Fully lower your arms`
- `Keep your elbows close to your sides`
- `Move both arms together`

### 3.4 Shoulder-press profile

Required landmarks: shoulders, elbows, and wrists on both sides; nose may help determine overhead wrist position.

Metrics:

- elbow extension at the top
- wrist height relative to shoulder/head
- wrist horizontal symmetry
- left/right completion timing
- torso lean

Detection considerations:

- Start with wrists near shoulder height and elbows flexed.
- Detect upward wrist travel and elbow extension.
- Peak when wrists are overhead and elbows approach extension.
- Complete when wrists return to the start region.

Feedback candidates:

- `Press a little higher`
- `Finish both arms evenly`
- `Keep your torso steady`
- `Return your hands to shoulder level`

### 3.5 Lateral-raise profile

Required landmarks: shoulders, elbows, wrists, and hips on both sides.

Metrics:

- arm elevation angle on each side
- elbow bend
- left/right elevation symmetry
- wrist height symmetry
- torso lean or side sway

Detection considerations:

- Start with wrists near hip level.
- Track increasing shoulder-to-wrist elevation.
- Peak around shoulder height.
- Complete when both wrists return near the hips.

Feedback candidates:

- `Raise your arms to shoulder height`
- `Lower your arms with control`
- `Keep both arms level`
- `Keep your torso still`

### 3.6 Jumping-jack profile

Required landmarks: shoulders, wrists, hips, knees, and ankles on both sides.

Metrics:

- normalized ankle separation
- wrist height and horizontal spread
- left/right limb timing symmetry
- knee/hip center stability
- cycle duration

Detection considerations:

- Closed state: feet near each other and arms down.
- Open state: feet separated and wrists above shoulder or head threshold.
- Complete on return to the closed state.
- Require both arm and leg signals so a partial arm-only motion is not counted as a full jack.

Feedback candidates:

- `Raise your arms fully`
- `Open your stance a little wider`
- `Bring your hands and feet back together`
- `Keep both sides moving together`

### Configuration and tuning

Thresholds belong in per-exercise profiles, not widgets. Start with conservative values derived from deterministic fixtures, then tune on the target device. Record camera view, distance, lighting, participant count, and final thresholds.

## 4. Human-friendly live feedback

### Goal

Translate structured evaluation results into one short, actionable instruction after each completed rep.

### Implementation

- Replace the single free-form `reason` with structured `RepIssue` values.
- Each issue contains exercise, metric, direction, severity, measured value, and optional baseline value.
- Use an exercise-aware feedback catalog to map issues to user-facing copy.
- Display the highest-priority message live and retain all issues for the summary.
- Keep warnings visible for approximately two seconds.
- Keep degraded feedback visible until the next rep or a tracking interruption.
- Do not expose internal identifiers such as `leftElbowAngle` in normal UI.

```dart
enum IssueDirection { belowRange, aboveRange, increased, decreased, asymmetric }

class RepIssue {
  final ExerciseId exercise;
  final MovementMetric metric;
  final IssueDirection direction;
  final double measuredValue;
  final double? baselineValue;
  final double normalizedSeverity;
}
```

### Message rules

- Describe observable movement, not danger.
- Prefer an instruction the user can apply on the next rep.
- When several issues occur, prioritize incomplete range, then strong asymmetry, then persistent baseline drift.
- Use generic fallback copy: `Your movement changed from your baseline`.
- Keep tracking errors separate from form feedback.

### Acceptance criteria

- Every exercise/issue combination has deterministic copy or a safe fallback.
- Internal metric names never appear in the UI.
- No copy uses clinical or injury-risk language.
- Tracking loss removes stale coaching immediately.

## 5. Tempo and range-of-motion measurements

### Shared per-rep metrics

- total duration
- outward/concentric duration
- return/eccentric duration
- peak-transition duration when measurable
- primary-joint range of motion
- optional secondary-joint range of motion
- left/right timing difference for bilateral exercises
- completion confidence

```dart
class RepMetrics {
  final Duration totalDuration;
  final Duration outwardDuration;
  final Duration returnDuration;
  final Duration? transitionDuration;
  final Map<MovementMetric, double> rangeOfMotion;
  final Duration? bilateralTimingDifference;
}
```

### Implementation

- Timestamp detector phase transitions with frame timestamps or a monotonic stopwatch.
- Record extrema while the attempt is active.
- Exclude sustained tracking-loss intervals or invalidate the affected rep.
- Report durations rounded to tenths of a second.
- Do not use tempo alone as proof of bad form; treat deviation as a consistency signal.
- Keep live UI limited to a small optional duration label. Put details in the summary.

### Exercise-specific range metric

- Squat: knee-angle excursion.
- Reverse lunge: lead-knee excursion and normalized step length.
- Bicep curl: elbow-angle excursion.
- Shoulder press: elbow extension and normalized wrist elevation.
- Lateral raise: arm-elevation excursion.
- Jumping jack: normalized stance-width and wrist-height excursion.

### Acceptance criteria

- Deterministic frame sequences produce correct phase durations.
- Durations cannot be negative.
- Range uses measured start and peak values.
- Low-confidence gaps do not silently inflate duration.
- Bilateral timing difference is unavailable, not zero, when one side is missing.

## 6. Rep timeline and score breakdown

### Summary questions

The summary must answer:

1. How did the set go overall?
2. When did movement begin to change?
3. Which exercise-specific measurement changed most?

### Rep timeline

Show one marker per rep:

- gray: calibration
- green: good
- amber: warning
- red: degraded

Tapping a marker reveals rep number, feedback, range of motion, tempo, confidence, and the relevant baseline comparison. The first degraded rep receives a visible callout while earlier warnings remain visible.

### Score breakdown

Every exercise shows these shared components when available:

- Range consistency
- Tempo consistency
- Control/return consistency
- Left/right symmetry

It also shows exercise-specific components:

- Squat: depth and torso consistency.
- Reverse lunge: lead-leg range, step consistency, and torso consistency.
- Bicep curl: curl range and elbow-position consistency.
- Shoulder press: overhead completion and arm symmetry.
- Lateral raise: elevation height and arm symmetry.
- Jumping jack: arm range, stance range, and coordination.

Suggested initial overall scoring:

- calibration reps excluded
- good = `1.0`
- warning = `0.5`
- degraded = `0.0`
- unavailable metrics excluded rather than scored as zero
- fewer than two evaluated samples displays `Not enough data`

### Implementation

- Extend `SessionSummary` with component scores, average metrics, and best/lowest-scoring rep.
- Calculate summaries in pure Dart using the selected `ExerciseProfile`.
- Build the timeline with lightweight Flutter widgets rather than a chart dependency.
- Scroll horizontally for long sets.
- Add semantics such as `Rep 6, warning, press a little higher`.

```dart
class ComponentScore {
  final String id;
  final String label;
  final double? percent;
  final int evaluatedRepCount;
}
```

### Acceptance criteria

- Calibration is excluded from every score.
- Missing metrics are not treated as failures.
- Component labels and rules change with the selected exercise.
- Timeline order matches rep order and degradation-start metadata.
- Empty, calibration-only, clean, warning, and degraded summaries are supported.
- Timeline remains usable at 320 px width and 200% text scaling.

## 7. Multi-set comparison and in-memory history

### Scope

- Store completed sets for the current app run only.
- No account, local database, cloud sync, or cross-device history.
- Do not retain camera frames or landmark streams.
- A workout may contain multiple sets of one exercise or sets from several supported exercises.

### Experience

After a set:

- `Next set` starts another set of the same exercise.
- `Change exercise` returns to the six-exercise selection screen without clearing completed sets.
- `Finish workout` opens a workout summary.

Compare sets only when they use the same exercise. Across different exercises, show workout totals without pretending the scores are biomechanically interchangeable.

### Workout summary

- exercises completed
- sets and reps per exercise
- Form Score per set
- average tempo and primary range metric per set
- degradation-start rep per set
- same-exercise comparison such as `Set 2 maintained curl range for 3 more reps`

### Implementation

```dart
class CompletedSet {
  final int setNumber;
  final ExerciseId exercise;
  final DateTime completedAt;
  final List<Rep> reps;
  final SessionSummary summary;
}

class WorkoutState {
  final List<CompletedSet> completedSets;
  final SessionState currentSession;
}
```

- Snapshot immutable completed sets before resetting live engines.
- Reset detector, smoothing, calibration, feedback, and countdown between sets.
- Preserve completed history when changing exercises.
- Group comparisons by `ExerciseId`.
- Use neutral language for differences within a configured tolerance.
- Normalize degradation-start comparisons by evaluated-rep count when set lengths differ.

### Acceptance criteria

- Completing a set appends exactly one immutable record.
- Next Set preserves exercise and history but clears the baseline.
- Change Exercise preserves history and loads a new profile.
- Cross-exercise sets are never directly ranked by raw joint angles.
- No image data is retained.
- Finishing or starting a new workout follows explicit reset behavior.

## 8. Persistent exercise history and analytics

### Scope and storage

- Analytics is local to one device. No account, backend, cloud sync, or cross-device claims.
- Persist versioned, bounded workout/session summaries with the already-installed `shared_preferences` package.
- Never persist camera frames, images, landmark streams, or raw pose samples.
- Persist only evidence needed for journal and trend views: exercise, local timestamp, set/rep outcomes, component scores, aggregate ROM/tempo/symmetry/consistency, degradation point, structured issues, feedback delivered, and optional user note.
- Different exercises have separate history and metric series. Raw angles/ranges from unrelated exercises are never combined or ranked.

### Core analytics

- Exercise-wise History: sessions and trends filtered to one exercise.
- Day-wise Journal and Activity Calendar: exercises, sets, reps, and overall Form Score by local day.
- Form Score, Range of Motion, Tempo, Consistency, Form Degradation Point, and Left/Right Symmetry trends where each metric is available.
- Issue Frequency and Rep Quality Distribution.
- Set-to-Set Comparison for same-exercise sets.
- Weekly Exercise Summary: exercises, sets, reps, average Form Score, and normalized strongest/weakest exercise.
- Exercise Journal Entry: set details, rep timeline, issues, tempo, ROM, feedback, and optional note.
- Workout Streak remains secondary to movement-quality analytics.

### Evidence-derived insights

- Improvement Areas and Recent Progress Summary compare only compatible same-exercise metrics.
- Best Set / Best Session and Personal Records use explicit supported fields such as Form Score, consistency, ROM consistency, tempo consistency, and reps before degradation.
- Feedback History links repeated coaching to the same measured issue and may say it improved only when later comparable data supports that claim.
- One session cannot establish a trend. Missing metrics create gaps, not zero values.
- Use explicit tolerance bands for `improved`, `declined`, and `unchanged`; do not imply that noise is progress.
- Every generated insight must be traceable to stored sessions and metrics. No LLM or independent inference layer is required.

### Acceptance criteria

- History survives restart and corrupt/unknown stored data cannot block a live session.
- Calendar grouping respects the device's local date.
- Exercise filters never mix incompatible raw measurements.
- No-data, one-session, missing-metric, and tied-result states use honest neutral language.
- Session notes are displayed as user-entered context, never app-measured fact.
- Trend charts are accessible and usable at 320 px width and 200% text scaling.
- Analytics charts use `fl_chart`, one primary metric per card, restrained labels/grid lines, and no cluttered multi-axis presentation.
- Retention is bounded and contains no pose/image data.

## 9. Haptic and audio feedback

### Behavior

- Calibration: no cue.
- Good: no cue by default.
- Warning: visual feedback by default.
- Degraded: one haptic pulse and one short local/system sound.
- Tracking loss: visual guidance without a repeating alarm.

### Implementation

- Trigger from the new completed-rep event, never from widget rebuilds.
- Deduplicate by session ID and rep number.
- Use Flutter `HapticFeedback` first.
- Prefer a system sound or small bundled asset; avoid a large audio package for one cue.
- Provide sound and haptic toggles.
- Do not cue while backgrounded or during tests.
- Ensure cue playback never blocks pose inference.
- Use the same cue behavior for all exercises; exercise-specific sounds add no hackathon value.

### Acceptance criteria

- Each degraded rep produces at most one enabled cue.
- Warning, good, and calibration reps do not trigger the degraded cue.
- UI rebuilds cannot replay cues.
- Disabled channels stay silent.
- Consecutive degraded reps remain individually deduplicated.

## Exercise selection UI

Replace the single Squat card with six cards using one reusable component. Each card shows:

- exercise name
- simple icon or pose illustration
- recommended camera view
- `Full body` or `Upper body` space requirement
- readiness badge during development only if an exercise is not yet demo-ready

Recommended order:

1. Squat
2. Bicep Curl
3. Lateral Raise
4. Shoulder Press
5. Reverse Lunge
6. Jumping Jack

This order places the most reliable static-position exercises first. Do not expose an exercise as available until its detector, evaluator, summary, tests, and device rehearsal pass.

## State-management changes

`SessionState.selectedExercise` must become an `ExerciseId` rather than the hard-coded string `squat`. The session controller receives the profile and detector from an exercise registry.

```dart
class ExerciseRegistry {
  ExerciseProfile profileFor(ExerciseId id);
  RepDetector detectorFor(ExerciseId id);
}
```

Required controller actions:

- `selectExercise(ExerciseId exercise)`
- `prepareSession()`
- `startCountdown()`
- `startTracking()`
- `acceptMovementFrame(MovementFrame frame)`
- `endSession()`
- `startNextSet()`
- `changeExercise()`
- `finishWorkout()`
- `resetWorkout()`

Maintain these boundaries:

- Pose mapping converts ML Kit landmarks into domain-safe coordinates and confidence values.
- Metric extraction calculates angles and normalized distances.
- Exercise detectors own phase transitions and completion.
- The shared evaluator owns baselines, thresholds, issues, persistence, and verdicts.
- Feedback formatting owns user-facing messages.
- Summary code owns scoring and aggregation.
- Widgets render state and invoke actions; they do not calculate movement quality.

## Testing strategy

### Shared unit tests

- joint-angle and normalized-distance geometry
- smoothing and reset behavior
- confidence aggregation
- structured issue prioritization
- evaluator baseline and persistence behavior
- summary scoring and missing-data behavior
- workout history and same-exercise comparison

### Per-exercise detector tests

For every exercise, include:

- one normal start-peak-start rep
- duplicate start frames do not create duplicates
- insufficient excursion is not a completed rep
- partial but deliberate attempt follows documented behavior
- low-confidence critical frames are rejected
- noisy boundary frames do not double count
- tracking loss resets or safely pauses phase state
- left/right or bilateral behavior is deterministic

### Widget tests

- six exercise cards select the correct profile
- preparation guidance changes by exercise
- countdown blocks rep recording
- live HUD renders exercise-specific feedback
- summary renders the correct component labels
- next set, change exercise, and finish workout preserve/reset correct state
- compact screen and large-text accessibility coverage

### Physical-device rehearsal

For each exercise, record:

- target device and Android version
- front or rear camera
- portrait or landscape orientation
- camera height and distance
- lighting
- expected and actual rep count
- false positive/negative observations
- final thresholds

At minimum, validate three scripted sets per exercise and one intentionally degraded set that demonstrates the expected feedback.

## Diagnostics

Provide a debug-only view or structured log containing:

- selected exercise and detector phase
- raw and smoothed metric values
- required-landmark visibility
- per-metric confidence
- selected side or bilateral mode
- rep extrema and duration
- processed-frame time
- active thresholds

Do not show these diagnostics in normal user mode or retain camera images.

## Performance and privacy constraints

- Pose inference remains fully on-device.
- Keep the Android display awake while RightPosture is foregrounded; allow normal sleep after leaving the app.
- Never store or transmit camera frames.
- Process one frame at a time and drop frames while the detector is busy.
- Keep smoothing buffers and workout history bounded.
- Update timelines and charts per completed rep, not per camera frame.
- Avoid rebuilding the camera controller when only the exercise profile changes, unless required for orientation/resolution.
- Cut cosmetic animation or audio before reducing tracking stability.

## Implementation phases

Implementation is split into small exit-gated slices in [`iterations.md`](iterations.md), with one standalone file per iteration under [`iterations/`](iterations/). That index is the canonical build order; this document remains the canonical behavior and acceptance specification.

The order is: lock current squat behavior, repair squat measurement reliability, introduce shared contracts, add shared setup/feedback/metrics, add each exercise as a complete vertical slice, add detailed summaries and workout comparison, persist summary-only history, build analytics, then add guided demos, checkpoint TTS, cues, and release hardening.

Each implementation session should load only its current iteration, linked sections from this specification, named files, and relevant failing tests. Do not implement later-iteration abstractions early.

## Hackathon cut line

Do not aim for six weak exercise cards. The demo is stronger with fewer exercises that count reliably and explain their output.

Recommended fallback order if time becomes limited:

1. Squat
2. Bicep Curl
3. Lateral Raise
4. Shoulder Press
5. Reverse Lunge
6. Jumping Jack

Keep an exercise hidden until its full vertical slice works: setup guidance, detector, evaluation, feedback, summary, tests, and a rehearsed target-device run.

## Definition of done

- The selection screen offers six genuinely working exercises.
- Camera guidance changes according to the selected movement.
- The app calibrates exercise-relevant metrics rather than assuming knee angles for every exercise.
- A scripted set for each exercise counts correctly on the target iQOO device.
- Deliberately reduced range, increased torso movement, or bilateral mismatch produces exercise-appropriate feedback where measurable.
- Brief landmark noise or occlusion does not create a false degraded rep.
- Tempo and range metrics use the selected exercise's primary movement signal.
- Summary labels, timeline details, and component scores match the exercise.
- Same-exercise sets can be compared; different exercises are grouped without invalid raw-angle comparisons.
- Local history supports exercise/day journals and evidence-based trends without storing pose or image data.
- Analytics never claims improvement without comparable same-exercise history.
- Degraded reps produce at most one enabled haptic/audio cue.
- Analyzer, unit tests, widget tests, Android build, and physical-device rehearsal pass.
- Known 2D-camera and venue limitations are documented honestly.


## Original demo/TTS notes preserved verbatim

```text
demo at the starting of the each exercise for the first time and then it can go for demo after first visit.
in demo:
the skeleton landmark should first ask the user to stand in a particular position.
then first instruction, then again check the posture
then next instruction
iterate these for 5 times

in real exercise:
don't do the tts for every rep.
at starting, it should give a summary by taking context of previous data (summary should include what is required to improve and what has improved - make sure not to hallucinate to speak anything whose data is not there e.g. if a user is doing everything good, then don't tell him about what was wrong at starting. also it should be understandable like you are going too lower in squats, try to keep your thighs parallel or in case of dumbells - you are taking your arm to 60 degree which ideally should be 45 degree. kind of something)
analyze and then provide the user tts feedback after 50% of total reps of each set. 
at the end, give tts summary (also) for the current session done.
```
