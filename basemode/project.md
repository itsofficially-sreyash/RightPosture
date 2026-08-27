# project.md

## What this is
Phone-first fitness form + form-degradation coach for iQOO Hackathon 2026 (Track: HealthTech).
Team: 3 people (full-stack mixed).
Event: City Battle, 30 hrs total (~19 hrs pure build: 10.5h Red Light phone-only, 8.5h Green Light phone+laptop).

## Product in one line
Live camera pose-tracking during an exercise set runs ONE evaluation pipeline (decision.md D8) that catches two kinds of form problems: a rep that's wrong from the start (absolute range check), and form that gradually degrades across the set (baseline + persistence check, decision.md D11) — both surfaced as a single per-rep status, not two separate app modes.

## Why this exists (do not lose this thread)
- Rehab-only apps ("did you do your exercises") ignore *how well* you did them mid-set.
- Fitness-counter apps ("AI gym buddy") ignore *why* a rep matters — they count, they don't warn.
- Nobody phone-first is running one pipeline that catches both "wrong immediately" and "degrading gradually" from the same rep stream. That's the differentiation. Say this explicitly in the pitch — it's a real algorithmic claim (decision.md D11), not marketing.

## Rubric mapping (keep visible, judge on this)
- End product quality (30%) — must actually work live, on-device, no crashes during demo.
- Novelty/impact (20%) — the two-layer-from-one-pipeline angle IS the novelty claim. Say it explicitly in the pitch.
- Technical depth (15%) — real-time pose landmark math (hand-written angle calculations, decision.md D3), angle-drift-over-time logic. No NPU-delegate claim to lean on anymore — depth has to come from the algorithm, not the hardware-acceleration story.
- Creative phone use (15%) — camera + on-device inference, no cloud round-trip.
- Office Kit (10%) — TBD, see workflow.md.
- Demo (10%) — 3-5 min, must show live camera working on the actual iQOO loaner, not a recording.

## Non-negotiable constraints
- 55% build time phone-only (Red Light). Do not architect anything that requires laptop mid-build.
- Must run on iQOO loaner device — verify `google_mlkit_pose_detection` runs smoothly (no unusable latency) on that hardware in Green Light hours, before committing further (decision.md D3).
- Team of 3 — MVP scope must fit 3 people, 19 hours. See features.md for cut lines.
