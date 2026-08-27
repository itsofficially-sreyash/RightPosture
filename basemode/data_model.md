# data_model.md
In-memory models only (no persistence in MVP, see tech_stack.md). These are Dart class shapes, not DB schemas.
REVISED — modes merged into one pipeline (decision.md D8). "Injury Risk" renamed "Form Degradation" throughout (decision.md D9 — unsupported clinical claim, killed).

## Exercise
- `id`: String (e.g. "squat", "lunge" — decision.md D4)
- `name`: String (display)
- `angleThresholds`: Map — per-exercise config with TWO parts now, not one:
  - absolute range: min/max angle at bottom-of-movement that counts as "correct form" regardless of baseline (catches a rep that's wrong from the start — old Form Check behavior).
  - deviationThreshold: normalized deviation magnitude from baseline that counts as a "warning" on a single rep.
  - persistenceCount: number of consecutive reps a deviation must hold before it's promoted from "warning" to "degraded" (old Risk Watch behavior, now folded in). Recommend 2 as a starting default — empirically tune in execution/04.

## PoseFrame
- `timestamp`: DateTime
- `landmarks`: List<Landmark> (from `google_mlkit_pose_detection`, 33 points, image-coordinate + per-landmark `InFrameLikelihood` confidence — decision.md D3)
- `jointAngles`: Map<String, double> (hand-written angle calc, no package helper — decision.md D3)

## Rep
- `repNumber`: int
- `angles`: Map<String, double> (key joint angles at bottom-of-movement for this rep)
- `confidenceOk`: bool (landmark confidence above threshold for the frames this rep was measured from — low-confidence reps are excluded from baseline computation and evaluation, error_handling.md)
- `status`: enum { good, warning, degraded } — REPLACES old separate `isFormCorrect`/`riskFlag` booleans. One unified per-rep verdict:
  - `good`: within absolute range AND within deviation threshold of baseline (or baseline not yet established).
  - `warning`: outside absolute range OR outside deviation threshold on this rep alone — first occurrence.
  - `degraded`: deviation from baseline has persisted for `persistenceCount` consecutive reps, OR absolute range violated (absolute violations don't need persistence — a rep with clearly wrong depth is wrong immediately, no baseline needed).
- `reason`: String? — required if status is warning/degraded (e.g. "knee angle 12° below acceptable range", "hip angle deviation persisting since rep 5").
- `responsibleJoint`: String? — which tracked joint drove the flag, for summary display.

## SessionState (Riverpod-managed, see statemanagement.md)
- `selectedExercise`: Exercise
- `reps`: List<Rep>
- `baseline`: Map<String, double>? — median of key joint angles from the first 2-3 valid (`confidenceOk == true`) reps. Null until established (see execution/04 algorithm). All deviation comparisons are against this, not against a fixed theoretical ideal.
- `status`: enum { idle, tracking, complete }
- NOTE: `mode` enum REMOVED — decision.md D8, single unified pipeline, no mode selection.

## SessionSummary (derived, computed at end of set from SessionState.reps)
- `totalReps`: int
- `formScorePercent`: double — `reps.where(status == good).length / totalReps` (renamed from `correctnessPercent`, decision.md D7's terminology note)
- `degradationStartRep`: int? — first rep number where status became `degraded`, null if none.
- `primaryResponsibleJoint`: String? — most frequently flagged joint across degraded reps, for the "primary movement change" summary line.
- `repChecklist`: List<{repNumber, status, reason}> — for the rep-by-rep ✓/⚠/❌ display (matches the desired-MVP example format).

## Open question, still unresolved
Exact absolute-range and deviation-threshold values per exercise are UNKNOWN until tested on a real person with real landmark data — this needs empirical tuning during build (execution/04), not guessed from theory.
