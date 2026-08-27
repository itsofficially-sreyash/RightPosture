# Iteration 05 — Session State and Wiring

## Goal

Connect pose samples to domain engine through minimal Riverpod state.

## Scope

- Create session controller holding selected exercise, phase, reps, baseline, latest feedback, and failure state.
- Feed valid joint samples into rep detector and record completed reps exactly once.
- Add explicit start, end, reset, and retry commands.
- Derive summary from completed session state.
- Ensure restart clears baseline, persistence counters, reps, and transient errors.
- Keep camera ownership outside session state; session consumes app-owned pose samples.

## Tests

- Calibration → tracking → complete flow.
- Duplicate frame/sample cannot record duplicate rep.
- End Set produces summary and stops evaluation.
- Reset removes all previous-session data.
- Camera/pose error becomes recoverable UI state.

## Exit gate

Controller tests pass with synthetic samples. No real camera needed for this iteration.

