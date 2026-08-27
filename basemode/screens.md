# screens.md
REVISED — mode select screen REMOVED (decision.md D8, modes merged). Onboarding screen ADDED (decision.md D12, reverses earlier cut). Four screens now.

0. **Onboarding** (new, P1 — decision.md D12)
   - Single full-bleed lime screen (kit style — see color_palette.md, ui/onboarding.md), app name/logo, one-line explainer, camera permission request as the primary CTA.
   - Shown once per app session (no persistence, per prd.md scope) — not a multi-step carousel, one screen only.
   - Skippable/cuttable first if time runs short (features.md).

1. **Exercise Select**
   - Fixed list per decision.md D4 (squat, lunge — lunge cuttable per execution/04 "if behind schedule").
   - First screen, no mode choice before it — one less decision for the user, one less thing to build.

2. **Live Session**
   - Camera feed, live skeleton overlay.
   - Rep counter, always visible.
   - Live per-rep status indicator (data_model.md `Rep.status`): good/warning/degraded, shown as the rep completes. Early in the set (before baseline established — first 2-3 valid reps), show a neutral "calibrating" state rather than a verdict — don't evaluate against a baseline that doesn't exist yet (data_model.md, execution/04).
   - P1: reason text on warning/degraded reps, audio/visual cue at the moment of a degraded rep.

3. **Session Summary**
   - Total reps, Form Score % (data_model.md `formScorePercent` — renamed from "compliance," decision.md D7 terminology note).
   - Rep-by-rep checklist: ✓ good / ⚠ warning / ❌ degraded, matching the desired-MVP format.
   - "Form degradation detected from Rep N" line if `degradationStartRep` is set, plus `primaryResponsibleJoint` ("Primary movement change: knee alignment deviation").
   - "Restart" → back to Exercise Select, full session state reset (baseline, reps, everything — statemanagement.md).
   - P2 stretch: export/share (mocked, decision.md D5) — only if time allows.

## Explicitly not building
- Mode select screen — removed, decision.md D8.
- Multi-step onboarding carousel — only ONE onboarding screen, decision.md D12.
- Settings screen.
- Login/profile screen.

## UI design system
Visual language (colors, typography, cards, animation) sourced from user-provided reference kit — see color_palette.md, design.md, and per-screen docs in ui/. Decision.md D13 — note the kit's own tab-based/multi-feature screens (Browse, Home Dashboard, Trainer Profiles) are NOT part of this app's scope; only the visual language is adopted, not those screens.
