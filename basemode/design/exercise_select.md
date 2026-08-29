# ui/exercise_select.md
Priority: P0 (features.md).

## Layout
Dark `bg-base` (#15161B) screen background, matching the kit's Browse/list screens minus the tab bar and filters (out of scope, decision.md D13).

- Simple header/title ("Choose your exercise" or similar), `text-primary` white.
- Up to six gated cards in delivery order from `../iterations.md`, using a responsive list/grid. Hide exercises that have not passed their vertical-slice/device gate.
- Each card: exercise name (bold, `text-primary`), a simple static icon or illustration representing the exercise (we have no photography like the kit's workout images — do not fake stock photos, use a clean icon/pictogram instead, it's honest about what this app actually is).
- Tapping a card selects it and transitions directly to Live Session — no intermediate "confirm" step, keep this fast since it's re-visited every time the user restarts (app_flow.md).

## States
- Default: both/all exercise cards visible and tappable.
- If lunge is cut per execution/04's "if behind schedule" clause (decision.md D4) — this screen simply shows one card instead of two. Don't leave a disabled/greyed-out placeholder for a cut exercise, that looks unfinished; just omit it.

## Animation (design.md)
- Card tap: brief scale-down/up feedback (~100ms) on tap, standard touch-feedback pattern, before the screen transition fires.
- Screen transition in/out: slide + fade, ~250-300ms, consistent across the app.

## Explicitly not building
- Filters, sorting, search — kit features from the Browse screen, not relevant to a 1-2 item list (decision.md D13).
- Exercise photography/video thumbnails — no time budget to source or shoot these, use simple icons instead.
