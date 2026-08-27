# error_handling.md
Hackathon-scoped: goal is graceful, non-crashing fallback for the demo, not comprehensive production error handling.

## Camera / permissions
- No camera permission granted → show a clear in-app prompt to grant it, don't crash. Test this explicitly (testing.md) since a judge picking up the phone cold could trigger this.
- Camera fails to initialize (rare, but possible on unfamiliar loaner hardware) → show an error state with a retry button, not a blank screen or crash.

## Pose detection
- No person / person exits frame → pause rep detection, show a neutral "step into frame" state. Do NOT count a rep or flag risk from an empty/partial pose read — this is a real failure mode (prd.md open risks) and a false flag here would look broken live.
- Low-confidence landmark data (poor lighting, occlusion) → `google_mlkit_pose_detection` exposes an `InFrameLikelihood` confidence score per landmark (0.0-1.0) — gate rep/flag logic on a minimum threshold using this. Confirmed available, per package docs (decision.md D3). Also feeds `Rep.confidenceOk` (data_model.md) — low-confidence reps are excluded from baseline computation, not just from live display, or a noisy baseline poisons every later comparison.
- Package fails to initialize/build on the loaner → this is a blocking failure with no pre-defined fallback (decision.md D3, dependencies.md) — resolved in execution/01_verify_hardware.md before any other chunk proceeds, not handled as a runtime fallback.

## Rep-detection / evaluation
- Ambiguous rep (angle state machine doesn't cleanly resolve standing→bottom→standing) → don't count a half-formed rep. Better to undercount than to show an obviously wrong rep number live.
- Single noisy frame causing a spurious deviation reading → this is exactly what the persistence requirement (decision.md D11) exists to absorb — a one-off deviation should register as `warning` at most, never `degraded`, until it persists across `persistenceCount` consecutive reps. If this isn't holding in testing, the algorithm implementation is wrong, not the noise.
- Baseline never establishes (e.g., first 2-3 reps are all low-confidence) → session should stay in "calibrating" state rather than silently evaluating against a missing baseline (screens.md) — surface this to the user rather than producing undefined behavior.

## General
- Any unhandled exception during Live Session screen → catch at the screen level, show "session ended unexpectedly, tap to restart" rather than a full app crash. A recoverable error in front of judges is much better than a crash — build this wrapper even if nothing else in this file gets full coverage.
