# decision.md
Running decision log. Append, don't delete history — if a decision is reversed, strike it and say why.

## D1 — Track: HealthTech (locked)
Was: Productivity (capture-friction idea). Killed because the eventual product idea (fitness/form) is HealthTech, not Productivity. Reopened track selection, locked HealthTech.

## D2 — Product direction: Hybrid, defined narrowly (locked, revised)
Rejected: pure rehab-compliance-only (Option A) and pure fatigue/injury-detector-only (Option B) as separate builds.
Rejected: naive "do both" hybrid as two fully separate analytic systems (scope creep — two products in one hackathon slot).
REVISED (was: two output layers, no user-facing split) — user now wants both presented as **separate features**, not just internal output layers. Locked resolution: ONE shared pipeline (pose landmarks → joint angles, single engine), user picks between two MODES at session start:
  - "Form Check" mode — rehab/compliance framing, per-rep correctness feedback, compliance %.
  - "Risk Watch" mode — injury-risk framing, angle-drift-over-set tracking, flags the risky rep.
Both modes are real, separately demoable, separately screen'd. They share the pose/angle engine so this is not a second build — it's one engine with a mode switch. If the actual intent is fully independent systems with no shared code, that is a bigger scope change — flag it, not yet built that way.
Open question, unresolved: primary demo narrative order (lead with Form Check or Risk Watch in the pitch). Decide before screens.md copy is finalized.

## D7 — Form Check vs Risk Watch: kept separate, with a demo-credibility condition (SUPERSEDED by D8)
Re-examined after user flagged the two modes look identical from the outside. Confirmed: the underlying computation IS different (Form Check = per-rep absolute threshold check, stateless; Risk Watch = trend/drift detection across sequential reps, needs a baseline). This is a real algorithmic distinction, not a relabel.
BUT: the distinction is invisible to a judge unless (a) it's narrated explicitly in the pitch, and (b) the Risk Watch demo shows a genuine trend, not a single rigged bad rep. Initially kept as two modes with this condition attached — SEE D8, this was reversed one exchange later.

## D8 — Merged into ONE pipeline, no separate modes (locked, reverses D2/D7)
Two independent critiques (Claude's own repeated pushback + a separate external review) converged on the same conclusion: two modes selecting the same camera/landmarks/angles/rep-stream, differing only in evaluation logic the user never sees directly, is artificial UX complexity, not a real feature split. User agreed after seeing convergence from a second, independent source.
Resolution: ONE evaluation pipeline. Per rep, compute an absolute range check (catches a rep wrong from the start — old Form Check job) AND a baseline-deviation-with-persistence check (catches gradual degradation — old Risk Watch job). Both feed into a single `Rep.status` (good/warning/degraded, data_model.md) instead of two parallel per-mode outputs. Mode-select screen removed (screens.md). This is strictly less to build, test, and demo than the two-mode version, and it directly matches the desired-MVP rep-by-rep checklist format from the external review.
Cost of this reversal: screens.md, features.md, data_model.md, statemanagement.md, testing.md, error_handling.md, and execution chunks 05/06/07/08/09 all needed rewriting to remove mode branching. Done as of this entry — verify no stray "mode," "Form Check," or "Risk Watch" language survives in any doc before treating this as complete.

## D9 — "Injury Risk" language killed, replaced with "Form Degradation" (locked)
External review correctly flagged: the system measures 2D pose landmarks, joint angles, and angle deviation — it has no clinical validation, force measurement, medical history, injury dataset, or biomechanical simulation. "Injury-risk detection" is an unsupported medical claim that a healthcare-background judge would correctly challenge, and there's no defensible answer to "how do you know this predicts injury." Renamed throughout: "Form Degradation Detection" / "form degradation" / "movement drift." Injury prevention may be mentioned as a POTENTIAL downstream benefit in the pitch, never as something the system diagnoses or detects directly.

## D10 — Terminology cleanup: "compliance" → "Form Score" (locked)
"Compliance" reads as a rehab/medical metric, inconsistent with the gym-user-primary framing already locked in prd.md. Renamed the correctness metric to "Form Score" throughout (data_model.md `formScorePercent`, was `correctnessPercent`/"compliance %").

## D12 — Onboarding screen added (locked, reverses earlier cut)
prd.md and features.md previously cut onboarding entirely ("hackathon demo, judges get a verbal walkthrough, not in-app hand-holding") — that was correct for a judge-narrated demo but user now wants it in the shipped app, per UI kit provided. Reversing: ONE onboarding screen only (not a multi-step carousel) — app intro + camera permission request, matching the kit's minimal full-bleed lime screen style (like the "Get ready" screen in the reference). Kept to P1, not P0 — the core loop (Exercise Select → Live Session → Summary) still works and is demoable without it; if build time runs out, cut this first, not the core loop. See screens.md, features.md, ui/onboarding.md.

## D13 — UI design system sourced from user-provided kit (locked)
Colors pixel-sampled directly from the uploaded reference image (not estimated) — see color_palette.md for exact values and sample method. The kit shows a much broader app (workout browsing library, home dashboard with steps/calories/water rings, trainer marketplace, workout detail with reviews, tab-based bottom nav) than our locked MVP scope. Extracted: color palette, typography feel, card/button/progress-bar visual language, animation tone. NOT adopted: tab-based bottom navigation (Home/Meal/Statistics/Rewards — we have no destinations for these, our app is a single linear flow), workout browsing/library screens, home dashboard, trainer profiles — all out of scope per prd.md's existing cuts, and adding them now would reintroduce the exact scope creep already rejected multiple times in this doc. If the team wants the full multi-tab app post-hackathon, that's a real scope conversation, not a UI styling task.

## D11 — Cross-rep evaluation algorithm: baseline + persistence, not naive delta (locked)
External review correctly flagged that a naive `if currentAngle - firstRepAngle > threshold: degraded` check is not credible — pose estimation noise (landmark jitter, occlusion, lighting, camera angle) would produce false positives from a single noisy frame. Adopted instead: baseline computed as the median of the first 2-3 valid (confidence-gated) reps; later reps compared against this baseline; a deviation must PERSIST across `persistenceCount` (default 2) consecutive reps before being promoted from "warning" to "degraded" (data_model.md `Exercise.angleThresholds`). Absolute range violations (rep wrong from the start) bypass the persistence requirement — those are flagged immediately, no baseline needed. This algorithm is now the spec for execution/04, not the vaguer "empirically tune drift threshold" language from earlier.

## D3 — Tech stack: Flutter + google_mlkit_pose_detection (locked, REVISED — flipped from flutter_pose_detection)
Was: `flutter_pose_detection`, chosen for its explicit Qualcomm QNN/Snapdragon NPU delegate claim and built-in angle-calculation helpers.
REVISED after comparing package stats: `google_mlkit_pose_detection` has ~150 likes/pub points and 19 published versions with active recent maintenance (AGP 8, SDK 35, Java 11 support), MIT licensed, real production Google ML Kit API (BlazePose-based, 33 landmarks, Android+iOS). `flutter_pose_detection` was ~120 points/~48 downloads, v0.4.0, young, unconfirmed license.
Reason for the flip: original choice over-weighted the NPU marketing claim against actual stability risk. NPU delegate control only feeds a fraction of two rubric lines (technical depth 15%, creative phone use 15%); package instability threatens end-product-quality (30%) directly, and the brief explicitly states a well-built simple product beats a broken complex one. Stability wins.
Known cost of this flip: no documented Snapdragon NPU delegate hook — do NOT claim NPU-specific acceleration in the pitch, ML Kit manages its own acceleration internally and this is unverified either way. Also: no built-in angle-calculation helpers — joint-angle math must be hand-written (~1-2 hrs dev time, low risk, but real time cost, budgeted into execution/03_pose_engine.md and execution/04_rep_detection_core.md).
Known caveat carried over: platform-channel-based Flutter pose detection has a documented latency tax in at least one comparable implementation — budget for "real-time" meaning smooth-enough, not zero-latency (already correctly avoided that language, see project.md).
Condition: still NOT yet verified on the actual iQOO loaner hardware specifically — this decision is provisional until execution/01_verify_hardware.md passes. No fallback package currently defined for this choice (previously ML Kit WAS the fallback; now nothing is). If ML Kit fails hardware verification, this needs a new decision, not an automatic fallback.

## D4 — Exercises in scope: Squat + Lunge (locked, default — override if wrong)
Chosen because both are sagittal/frontal-plane reliable for monocular 2D pose (per prd.md open risks — no depth judgment needed), and both map cleanly to a standing→bottom→standing rep state machine (data_model.md). Not confirmed by user explicitly — this is the lowest-risk default, flag now if a different exercise pair is wanted.

## D5 — "Send to physio" / compliance report: MOCKED, not real
No clinic integration exists or will exist by demo time. Any "share with physio" feature is a local PDF/export mock. Must be stated as such in the pitch — do not imply a real integration. Judges score self-reported device claims at 0%; only measured device data (25%) and jury eval count, but a false claim caught live wrecks end-product-quality trust (30%).

## D6 — Office Kit plan: screen mirroring during pitch (locked, default — override if wrong)
No feature built for Office Kit. Instead: mirror the live phone demo to a laptop screen for judges via Office Kit during the 3-5 min pitch (workflow.md Option 1). Zero build cost, satisfies "measured usage" of the phone-to-laptop bridge without diverting build time from P0/P1 features. If Office Kit's 10% needs a stronger showing than passive mirroring, that's a real scope add — flag it, not assumed here.

