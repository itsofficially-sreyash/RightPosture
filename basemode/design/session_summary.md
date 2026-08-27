# ui/session_summary.md
Priority: P0 (features.md). Direct template match to the kit's Congratulations screen (design.md) — this is the strongest kit-to-app mapping in the whole project.

## Layout
Full-bleed `accent-lime` (#D6FF5A) background, matching the kit's Congratulations screen structure exactly:

- Icon/checkmark area, centered upper-middle — dark circle (`surface-card-elevated` #2D2D35) with a checkmark, OR adapt to the session's actual outcome (see States below, this isn't always a pure "success" moment).
- Headline stat: Form Score % (data_model.md `formScorePercent`), large bold numeral, matching the kit's big-numeral treatment.
- Supporting text line(s): total reps, and "Form degradation detected from Rep N — [responsible joint]" if `degradationStartRep` is set (data_model.md `SessionSummary`) — never phrase this as injury risk (decision.md D9).
- Rep-by-rep checklist below the headline: ✓ good / ⚠ warning / ❌ degraded per rep, matching the desired-MVP format from the external review that shaped decision.md D11.
- Single CTA button, bottom: "Restart" — dark pill button on the lime background, kit's "Close" button pattern adapted.
- P2 (only if time allows): export/share button (mocked, decision.md D5) — do not build unless P0/P1 elsewhere is fully done.

## States
- **Clean set (no degradation)**: full celebratory treatment as above, checkmark icon, high Form Score %.
- **Degradation detected**: same layout, but the icon/tone should read as informative rather than purely celebratory if Form Score % is low — don't force a checkmark/success visual on a session that actually went poorly, that would misrepresent the result to the user and undercut the tool's credibility. Consider a neutral icon (e.g. a simple stat/chart glyph) instead of a checkmark when degradation was detected, checkmark reserved for genuinely clean sets.
- **Very short/incomplete session** (e.g. user backed out early): don't show a full summary with unearned confidence in a 1-2 rep session — see prd.md's success criteria note that persistence-based degradation needs a real set length to mean anything; if the set was too short to evaluate meaningfully, say so plainly rather than showing a potentially misleading Form Score.

## Animation (design.md)
- Entrance: fade-in + slight upward slide, ~300-400ms, matching the kit's implied celebratory-moment feel.
- Checklist items: consider a quick staggered fade-in per row (~50ms stagger) rather than all appearing instantly — low cost, reads as polish, don't over-invest time here.
- Restart button: standard tap feedback, then triggers the slide+fade transition back to Exercise Select (app_flow.md) with full state reset.

## Explicitly not building
- Confetti/particle effects — the kit doesn't show this, and it's exactly the kind of polish that costs build time without rubric payoff (design.md's animation guidance already flags this).
- Multiple summary "tabs" or sections — one scrollable screen, not a tabbed results dashboard (decision.md D13, no tab navigation anywhere in this app).
