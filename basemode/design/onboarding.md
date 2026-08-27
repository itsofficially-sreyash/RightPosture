# ui/onboarding.md
Priority: P1 (features.md, decision.md D12) — build after all P0 screens are solid, cut first if behind schedule.

## Layout
Single full-bleed `accent-lime` (#D6FF5A) background screen — matches the kit's "Get ready" screen pattern (design.md), the only kit screen close to an onboarding moment.

- App name/logo, centered upper-middle.
- One line of explainer text below it, dark text (`bg-base` #15161B or `surface-card-elevated` #2D2D35 for contrast against the lime background) — something like "Point your camera, we'll watch your form." Keep to one line, this is not a feature tour.
- Single CTA button, lower third: "Get Started" or similar, dark pill button on the lime background (inverse of the kit's usual lime-on-dark button, since the whole screen is already lime).
- Tapping CTA triggers the camera permission system dialog directly — don't add a second explanatory screen before the actual OS permission prompt, that's the multi-step carousel this screen is explicitly not (decision.md D12).

## States
- Default: as above.
- Permission granted → proceed immediately to Exercise Select, no confirmation screen needed.
- Permission denied → do NOT dead-end here. Show the error_handling.md permission-denied fallback prompt (in-app explanation + retry/settings link) on this same screen, don't silently fail.

## Animation (design.md)
- Entrance: fade-in on app launch, ~250ms.
- Exit transition to Exercise Select: slide + fade, ~250-300ms, consistent with every other screen transition in this app (design.md) — don't give this screen a unique/different transition style, consistency reads as more polished than novelty here.

## Explicitly not building
- Multi-step feature carousel/tour.
- Skip button as a separate flow from the permission ask — there's nothing to skip past, this is one screen.
