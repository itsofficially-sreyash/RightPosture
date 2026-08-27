# features.md
Priority: P0 = demo dies without it. P1 = strengthens score, cuttable under time pressure. P2 = only if P0/P1 done early.
REVISED — modes merged into one pipeline (decision.md D8), "injury risk" renamed "form degradation" (decision.md D9).

## P0 — Must work for the demo to exist
- Camera feed + live pose landmark overlay (skeleton drawn on user in real time).
- Rep counter using angle-based state machine (standing→bottom→standing = 1 rep).
- Exercise selection screen (fixed list, decision.md D4).
- Baseline establishment from first 2-3 valid reps (data_model.md, execution/04) — the noise-robust foundation everything else depends on.
- Unified per-rep evaluation: absolute range check + baseline-deviation check + persistence-based degradation detection, producing ONE status per rep (good/warning/degraded) — not two separate mode outputs.
- Session Summary: total reps, Form Score %, rep checklist, degradation-start-rep callout if applicable.

## P1 — Strengthens rubric score, cut if behind schedule
- Onboarding screen (single screen, app intro + camera permission ask) — decision.md D12, reverses earlier cut. Cheap to build, cuttable first under time pressure.
- On-screen reason text per warning/degraded rep (explainability — supports technical depth).
- `primaryResponsibleJoint` shown in summary ("knee alignment deviation" style callout) — this is the line that makes the degradation detection legible to a judge, worth prioritizing over other P1s if time is tight.
- Visual/audio cue at the moment a rep is flagged degraded, live during the set, not just on the summary screen.
- Basic session history within the same app run (not persisted) — lets you show a second set live.

## P2 — Do not build unless P0 and P1 are fully done with hours to spare
- Exported/shareable summary (mocked, decision.md D5).
- Second exercise beyond the primary one (lunge, if squat is solid — execution/04).

## Explicitly rejected (do not resurrect under time pressure)
- Calorie counter — no reliable input data.
- Pre-rendered "ideal form" GIF/3D dummy — replaced by live skeleton overlay.
- Multi-exercise library, user accounts, cloud sync.
- Two separate modes (Form Check / Risk Watch as distinct user-facing flows) — merged into one pipeline, decision.md D8. Do not rebuild the mode-select screen or a second evaluation path under time pressure; the whole point of the merge was to cut this exact complexity.
- "Injury risk" as a claim anywhere in the app or pitch — unsupported, killed, decision.md D9. Use "form degradation."
