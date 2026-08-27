# design.md
Visual design system, derived from the user-provided reference kit (decision.md D13). This describes patterns observed in the kit and how they map to OUR four screens (screens.md) — it does not describe the kit's full app, most of which is out of scope (browsing library, home dashboard, trainer marketplace — see decision.md D13's explicit "not adopted" list).

## Typography (observed pattern, exact font not verifiable from a screenshot)
- Bold, condensed-leaning sans-serif for headings ("Congratulation", "Get ready", rep counter "10") — high weight, tight tracking.
- Regular weight for body/muted text, clear size step-down from headings (roughly 2-2.5x size ratio between heading and body, visually).
- Numerals are a specific focal point in this kit (steps count, calorie count, big rep number) — always rendered large and bold, often in `accent-lime` or high-contrast white. Recommend the same treatment for Form Score % and rep count in our Live Session/Summary screens.
- Exact typeface is not determinable from a screenshot — use a clean geometric/grotesk system font (e.g. Inter, or Flutter's default) rather than guessing the source font name.

## Layout & spacing (observed pattern)
- Generous rounded corners throughout — cards, buttons, and image containers all use a large radius (visually ~20-24px equivalent), never sharp corners. Apply consistently to exercise-select cards, summary stat cards, and buttons.
- Consistent outer padding on screens (content doesn't touch edges), comfortable spacing between stacked cards (not cramped).
- Full-bleed color screens (lime background, no card chrome) used specifically for transitional/emotional moments — "Get ready" (anticipation) and "Congratulation" (completion). This maps directly to our Onboarding screen and is worth considering for a brief pre-set "get ready" transition before Live Session starts, and reusing the Congratulations pattern for Session Summary's positive-outcome state.

## Components (observed, mapped to our screens)
- **Cards**: dark surface (`surface-card`), rounded, contain image + title + metadata row (icon + label pairs, e.g. "45 min", "AAA Hard"). Maps to: Exercise Select cards (exercise name + a static illustrative icon, since we have no exercise photos — see ui/exercise_select.md).
- **Big numeral + progress bar**: the live exercise screen (10, progress bar, Previous/Next) is the closest kit pattern to our Live Session screen. Adapt: numeral = rep count, progress bar = set completion (reps done / target), but replace the static photo background with the live camera feed + skeleton overlay (our core technical feature — don't let a photo background pattern override showing live inference).
- **Full-bleed status screen**: the Congratulations screen (checkmark circle, big lime bg, stat line, single CTA button) is the direct template for Session Summary's overall shape — checkmark/icon, headline stat (Form Score %), supporting text (degradation callout if any), single "Restart" CTA. See ui/session_summary.md.
- **Buttons**: pill/rounded-rect, high-contrast (lime-on-dark or dark-on-lime), single clear CTA per screen rather than multiple competing actions — consistent with our screens.md's minimal-screen philosophy.
- **Bottom tab nav**: present throughout the kit (Home/Meal/+/Statistics/Rewards) — NOT adopted (decision.md D13). Our app has no tab destinations; a bottom nav bar with disabled/fake tabs would be worse than no nav bar. Do not build this.

## Animation & transition guidance (per user request — instructions for implementation, not yet built)
The kit's visual style (bold color blocks, big numerals, checkmark moments) implies motion opportunities even though a static screenshot can't show actual animation. Concrete guidance for implementation:

- **Screen transitions**: use Flutter's standard `PageRouteBuilder` with a subtle slide + fade (250-300ms, ease-out curve) between Onboarding → Exercise Select → Live Session → Summary. Avoid flashy/long transitions — hackathon judges are watching a live demo, a 300ms transition reads as polish, anything over ~400ms starts to feel like the app is slow.
- **Rep counter increment**: animate the big numeral with a quick scale-pulse (e.g. 1.0 → 1.15 → 1.0 over ~150ms) each time a rep completes — this is a high-value, low-cost animation since the rep counter is the single most-watched element during the live demo.
- **Status change (good → warning → degraded)**: crossfade the status indicator color/icon rather than an instant cut (150-200ms fade) — instant color-swaps read as glitchy on a projector/demo screen, a fade reads as intentional.
- **Baseline "calibrating" state**: a subtle pulsing/breathing opacity animation on the "calibrating" indicator (screens.md) communicates "the system is actively working" during the first 2-3 reps, rather than looking frozen or broken.
- **Progress bar fill**: animate fill transitions (not instant jumps) as reps complete, matching the kit's progress bar pattern — smooth easing, ~200-300ms per update.
- **Session Summary entrance**: the kit's Congratulations screen implies a celebratory entrance — a simple fade-in + slight upward slide (300-400ms) for the checkmark/headline stat is enough; do not over-invest in complex confetti/particle animations, that's build time better spent on the P0 evaluation pipeline (features.md priorities still apply — animation is polish, not core).
- **Performance note**: verify all animations stay smooth on the actual iQOO loaner (execution/01_verify_hardware.md already tests raw camera/pose performance — re-check that added UI animation doesn't compete for frame budget with the live pose-detection rendering, since that's the one thing that cannot stutter during the demo).

## Explicitly not adopted from the kit
Workout browsing/filtering UI, home dashboard rings/stats, trainer profile layout, review/rating components, tab-based bottom navigation — all belong to kit screens outside our locked scope (decision.md D13, prd.md). Extracting these patterns now would be scope creep the team has already explicitly rejected multiple times in this project's decision history.
