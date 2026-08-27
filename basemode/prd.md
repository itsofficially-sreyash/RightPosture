# prd.md
REVISED — modes merged (decision.md D8), "injury risk" killed (decision.md D9), terminology cleaned (decision.md D10), algorithm upgraded (decision.md D11).

## Problem
People doing exercise sets don't get real-time feedback on form, and nobody flags the point mid-set where form starts degrading — not because the rep suddenly failed, but because it drifted gradually (fatigue, loss of attention). Existing apps either count reps (no correctness signal) or check a single rep in isolation (no trend signal). SOURCE: this problem framing is our own claim, not externally validated market research — say so if asked.

## Users
Primary: gym/home-workout user doing bodyweight sets (squats, lunges) who wants form feedback and to know when their form is breaking down. Rehab framing (prior consideration) dropped — see decision.md, it introduces clinical-credibility questions (which injury, whose protocol, whose thresholds) the MVP can't answer. Can be mentioned as a future direction in the pitch, not built.

## Core loop (this is the entire MVP — do not add loops)
1. User selects exercise from a short fixed list.
2. User starts camera, does a set.
3. Live: skeleton overlay, rep counter, per-rep status (good/warning/degraded) as each rep completes. First 2-3 reps establish a baseline silently — shown as "calibrating," not evaluated against a verdict yet (data_model.md, execution/04).
4. End of set: summary — reps, Form Score %, rep-by-rep checklist, "form degradation detected from Rep N" + responsible joint if applicable.
5. Optional stretch: export summary as shareable text/PDF (mocked, decision.md D5).

## Success criteria for the demo
- Live camera + skeleton overlay renders on the iQOO loaner with no crash, in front of judges.
- Rep count is correct for a scripted, rehearsed set.
- The demo set is LONG ENOUGH (6-8+ reps) to show a genuine baseline-then-drift pattern — a short 2-3 rep set can't demonstrate degradation credibly, since persistence-based detection (decision.md D11) needs real reps to persist across. This replaces the earlier "under 90 seconds" framing where relevant — a slightly longer demo set is a required tradeoff for a credible degradation claim, not a nice-to-have.
- At least one deliberately-degraded stretch of reps late in the set gets correctly flagged, live.

## Out of scope (explicit)
- User accounts / auth / persistence across sessions.
- Exercises beyond the 1-2 locked in decision.md D4.
- Real physio/clinic integration.
- Calorie estimation.
- Multi-person-in-frame handling.
- Two separate user-facing modes — merged, decision.md D8.
- Any claim of diagnosing or predicting injury — killed, decision.md D9.

## Open risks (unresolved, need answers before build)
- Monocular camera can't judge depth reliably — exercise choice respects this (decision.md D4).
- Occlusion, venue lighting untested.
- `google_mlkit_pose_detection` smoothness/latency on iQOO loaner unverified until execution/01 passes — no fallback package defined (decision.md D3).
- Baseline+persistence algorithm (decision.md D11) is untested until execution/04 — the concept is sound, the exact threshold/persistence-count values are unknown until tuned on a real person.
