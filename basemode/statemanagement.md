# statemanagement.md
Riverpod (locked). REVISED — modes merged (decision.md D8), one evaluation pipeline, no mode branching in providers.

## Providers (minimum viable set)

- `cameraControllerProvider` — `Provider`/`FutureProvider`, wraps `camera` package controller lifecycle. Unchanged.

- `poseStreamProvider` — `StreamProvider<PoseFrame>`, wraps `google_mlkit_pose_detection` output, includes hand-written angle calc (decision.md D3). Unchanged — single source all downstream logic consumes.

- `sessionStateProvider` — `StateNotifierProvider<SessionStateNotifier, SessionState>`. Holds exercise, rep list, baseline, status (data_model.md SessionState — `mode` field removed). Notifier methods: `startSession`, `recordRep` (also updates baseline once the first 2-3 valid reps are in), `endSession`.

- `repEvaluationProvider` — RENAMED from `repDetectionProvider`, and now does the FULL merged evaluation in one place instead of branching into two mode-specific providers. Reads `poseStreamProvider` + current `Exercise` thresholds + `sessionStateProvider.baseline`:
  1. Runs the standing→bottom→standing state machine to detect a completed rep.
  2. Checks absolute range (data_model.md `Exercise.angleThresholds`) — violation = immediate `warning` or `degraded`, no baseline needed.
  3. If baseline established, computes deviation from baseline, checks against `deviationThreshold`.
  4. Tracks consecutive-deviation count to decide `warning` vs `degraded` (`persistenceCount` logic, data_model.md).
  5. Calls `sessionStateProvider.recordRep()` with the resulting `Rep` (single status, not two separate mode outputs).

- `sessionSummaryProvider` — derived `Provider`, computes `SessionSummary` (data_model.md) from `sessionStateProvider.reps` when `status == complete`. One summary shape, no mode-specific body.

## Why this shape
One shared camera/pose stream, one shared rep-evaluation core producing ONE verdict per rep instead of two parallel verdicts from two mode-specific evaluators. This is simpler than the previous two-mode architecture, not just relabeled — there is no mode field anywhere in this provider graph anymore (decision.md D8).

## Explicit no's
- No mode-selection provider — removed.
- No global app-wide state beyond session — no user profile, no persistence, per prd.md scope.
- Don't reach for Riverpod code-gen unless a team member is already fluent — plain `StateNotifierProvider`/`Provider` is faster to debug under time pressure.
