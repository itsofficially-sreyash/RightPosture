# testing.md
Hackathon-scoped testing — the goal is "doesn't break live in front of judges," not production QA coverage. Prioritize accordingly.
REVISED — modes merged (decision.md D8), so mode-switch tests removed; baseline/persistence algorithm tests added (decision.md D11).

## Must-test before Evaluation Round 1
- Camera + pose overlay actually runs on the iQOO loaner (not just a dev's personal phone/emulator) — this is the single most important test in the whole project, per decision.md D3 and workflow.md.
- Rep counting is correct for a scripted, rehearsed set (not required to generalize — see prd.md success criteria).
- Baseline establishes correctly from the first 2-3 valid reps, and a rep's status (good/warning/degraded) is evaluated only after the baseline exists — verify the "calibrating" period actually withholds verdicts (screens.md, execution/04).
- A deliberately-degraded stretch of reps (not just one bad rep) correctly transitions from warning → degraded once the persistence count is met (decision.md D11) — test the actual persistence logic, not just a single-rep flag.
- A single noisy/bad frame (e.g., brief occlusion) does NOT trigger a false degraded flag on its own — this is the entire point of the persistence requirement, verify it actually holds under real noise, not just clean test conditions.
- App doesn't crash on: no camera permission granted, poor lighting, person exits frame mid-set. Verify it doesn't crash, not that it "handles it well" (error_handling.md).

## Should-test if time allows
- Angle thresholds hold up across more than one team member's body/height (not just the person who tuned them).
- Venue lighting conditions, once known (unresolved per prd.md open risks).

## Explicitly not testing (out of scope for hackathon)
- Automated unit/widget test suite.
- Cross-device testing beyond the iQOO loaner.
- Load/performance testing beyond "does it run smoothly for one live demo."
- Mode-switch testing — removed, no modes exist anymore (decision.md D8).

## Demo rehearsal (not optional)
Run the full scripted demo (exercise select → live session with a long-enough set showing calibration then genuine degradation → summary) start to finish, timed, at least twice before Evaluation Round 1, and once before the final Sunday demo. Per prd.md's revised success criteria, this set needs to be long enough (6-8+ reps) to show real persistence-based degradation — don't rehearse a short set that can't actually demonstrate the claim.
