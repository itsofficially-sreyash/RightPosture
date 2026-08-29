# workflow.md

## Time allocation (per brief section 6 — ~19hrs pure build, 55/45 split)
- Red Light (~10.5h, phone only, laptop routed through Office Kit): use for anything that's pure Flutter/Dart logic you can iterate on-device — UI screens, state management wiring, rep-detection state machine logic once thresholds are roughly known.
- Green Light (~8.5h, phone+laptop): use FIRST for the highest-risk unknowns — `google_mlkit_pose_detection` smoothness/latency check on the real iQOO loaner (decision.md D3), and empirical angle-threshold tuning (data_model.md open question). Don't spend Green Light hours on things Red Light could have covered.
- Do the risky verification (package build, camera+pose hello-world) in the OPENING Green Light window if the schedule allows it — per brief section 6, Green Light covers "opening sprint" — not saved for later. If forced to wait for Red Light first, budget the first Green Light block entirely for this, before any new feature work.

## Team split (3 people) — assign, don't leave ambiguous
- Suggest: 1 person owns pose/camera pipeline + rep-evaluation core, including the baseline+persistence algorithm (highest technical risk, needs to start first — decision.md D11). 1 person owns Flutter UI/screens + Riverpod wiring. 1 person owns the summary layer once the core stream exists, plus demo-script/pitch prep. Adjust to actual skill split — this is a default, not a mandate.

## Office Kit (10% of score)

Mirror live phone demo to laptop during pitch (decision.md D6). No dashboard, export bridge, or app subsystem.

## Checkpoints (per brief section 8 timeline)
- By Mentor Round 1 (~15:30): pose pipeline should be verified working on-device (decision.md D3 condition resolved one way or the other).
- By Evaluation Round 1 (19:00-22:00): P0 feature list should be demoable end-to-end, even roughly. This is a scored checkpoint — treat it as a demo rehearsal, not just a status update.
- Sunday Evaluation Round 2: full demo on the iQOO phone, per features.md priority (P1 included only if P0 is solid).

## Git/build hygiene
- Not specified by user yet — add branch strategy / commit convention here once team agrees on one. Left open deliberately rather than assumed.

## Iteration workflow

- Use `iterations.md` as index; load one file from `basemode/iterations/` at a time.
- Do not scaffold analytics before Iteration 14. Do not expose an exercise before its device gate.
- After each iteration, update `progress.md` with checks, evidence, cuts, blockers, and next file.
