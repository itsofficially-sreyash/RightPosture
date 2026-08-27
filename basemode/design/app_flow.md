# app_flow.md
Complete flow, updated to include Onboarding (decision.md D12) and the merged single-pipeline architecture (decision.md D8). Four screens total, one linear path — no branches, no tabs (decision.md D13).

```
App Launch
   ↓
Onboarding  [P1 — decision.md D12]
   - Full-bleed lime screen (design.md), app intro, camera permission CTA
   - Transition: fade + slight upward slide, ~300ms (design.md)
   ↓ (permission granted → proceed; denied → error_handling.md fallback prompt, stay on this screen)
Exercise Select  [P0]
   - Squat / Lunge cards (decision.md D4, lunge cuttable)
   - Transition: slide + fade, ~250-300ms
   ↓ (pick exercise)
Live Session  [P0]
   - Camera feed + live skeleton overlay
   - Rep counter (big numeral, scale-pulse animation per rep — design.md)
   - Status indicator per rep: "calibrating" (first 2-3 reps, pulsing) → good / warning / degraded
     (crossfade transition between states, 150-200ms — design.md, error_handling.md)
   - Progress bar (animated fill, tracks reps done / target)
   ↓ (set ends — target reps reached or user stops)
Session Summary  [P0]
   - Congratulations-style full-bleed layout (design.md)
   - Total reps, Form Score % (data_model.md, renamed from "compliance" — decision.md D10)
   - Rep-by-rep checklist (✓ good / ⚠ warning / ❌ degraded)
   - "Form degradation detected from Rep N" + responsible joint, if applicable (never "injury risk" — decision.md D9)
   - Entrance: fade-in + upward slide, ~300-400ms
   ↓ (Restart button)
   → back to Exercise Select (full session state reset — baseline, reps, status all cleared, statemanagement.md)
```

## What's NOT in this flow (explicit, matches decision.md D13)
- No Home dashboard, no workout browsing/library, no trainer profiles — kit screens outside scope.
- No bottom tab navigation — nothing to navigate to beyond this one linear path.
- No mode selection — merged into one pipeline (decision.md D8).
- No login, settings, or account screens (prd.md).

## Screen count and priority recap
| # | Screen | Priority | Doc |
|---|---|---|---|
| 0 | Onboarding | P1 (cuttable first) | ui/onboarding.md |
| 1 | Exercise Select | P0 | ui/exercise_select.md |
| 2 | Live Session | P0 | ui/live_session.md |
| 3 | Session Summary | P0 | ui/session_summary.md |

If Onboarding is cut under time pressure (features.md), the flow simply starts at Exercise Select with the camera-permission prompt handled reactively (error_handling.md's existing "permission denied → in-app prompt" fallback covers this case either way — cutting Onboarding doesn't remove permission handling, just the proactive intro screen).
