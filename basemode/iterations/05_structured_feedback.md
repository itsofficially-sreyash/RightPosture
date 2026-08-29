# Iteration 05 — Structured feedback

## Status

Software complete on 2026-08-28. Feedback wording and thresholds require target-device validation.

Device correction: squat depth has no minimum knee-angle rejection. The app lacks evidence to label a deep squat harmful; it only flags insufficient depth and baseline change.

## Depends on

Iteration 04.

## Goal

Make feedback deterministic, actionable, evidence-based.

## Build

- Replace evaluator free text with `RepIssue`.
- Add priority selector, squat feedback catalog, safe fallback.
- Clear stale feedback on tracking loss.

## Exit

- UI exposes no internal metric identifiers.
- Every supported squat issue has deterministic copy or fallback.
- No unsupported or clinical correction appears.

## Cut

Text only. No new TTS behavior.
