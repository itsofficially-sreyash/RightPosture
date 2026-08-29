# Feature priority and release gates

Final behavior is defined in `rightposture_merged_spec.md`. Delivery order is defined in `iterations.md`.

## Foundation — required before any new exercise

- Reliable confidence propagation, smoothing, stable-side selection, and partial-attempt handling.
- Shared `MovementFrame`, exercise profile, detector, evaluator, and registry contracts.
- Exercise-aware preparation, positioning, and countdown.
- Structured issues, deterministic feedback, tempo, and range metrics.
- Squat regression and physical-device gate.

## Exercise vertical slices

Ship in this order:

1. Squat
2. Bicep Curl
3. Lateral Raise
4. Shoulder Press
5. Reverse Lunge
6. Jumping Jack

An exercise is visible only when setup guidance, detector, evaluator, feedback, summary labels, automated tests, and three target-device sets pass.

## Shared product features

- Rep timeline and component score breakdown.
- In-memory multi-set workout and same-exercise comparison.
- First-visit five-step guided demo.
- Evidence-based TTS at pre-set, midpoint, and post-set checkpoints.
- Deduplicated degraded-rep haptic/audio cues and settings.
- Local summary-only history, day/exercise journal, supported metric trends, issue frequency, records, and evidence-linked progress insights.

These follow their `iterations.md` gates. Do not start one early because its UI looks easy.

## Explicitly deferred

- Accounts, custom DB layer, backend, cloud sync, retained pose/images, multi-person tracking.
- Generative/cloud coaching, rep-by-rep TTS, exercise-specific sounds.
- Chart packages beyond approved `fl_chart`, code generation, or speculative detector framework.
- Push-ups, planks, deadlifts, floor exercises, calories, and real clinic integration.
