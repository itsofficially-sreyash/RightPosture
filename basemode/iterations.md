# RightPosture delivery iterations

Canonical build order for `rightposture_merged_spec.md`. Open only current iteration file, linked spec sections, named code files, and relevant tests.

## Rules

- Finish one iteration before starting another; preserve passing paths.
- Add no later-iteration scaffolding. Keep unfinished exercises hidden.
- Store no camera frames or landmark streams.
- Run listed checks and update `progress.md`.
- Stop at physical-device gates.

## Index

| ID | Iteration | Result |
|---|---|---|
| 00 | [Lock current squat behavior](iterations/00_lock_squat.md) | Regression baseline |
| 01 | [Reliable squat frames](iterations/01_reliable_frames.md) | Confidence, side lock, smoothing |
| 02 | [Partial squat attempts](iterations/02_partial_attempts.md) | Attempts separated from quality |
| 03 | [Shared exercise contracts](iterations/03_shared_contracts.md) | Squat on reusable boundary |
| 04 | [Preparation and countdown](iterations/04_preparation_countdown.md) | Camera-ready start gate |
| 05 | [Structured feedback](iterations/05_structured_feedback.md) | Evidence-based issues/copy |
| 06 | [Rep metrics](iterations/06_rep_metrics.md) | Tempo/range evidence |
| 07 | [Bicep curl](iterations/07_bicep_curl.md) | Upper-body slice |
| 08 | [Lateral raise](iterations/08_lateral_raise.md) | Bilateral elevation slice |
| 09 | [Shoulder press](iterations/09_shoulder_press.md) | Overhead slice |
| 10 | [Reverse lunge](iterations/10_reverse_lunge.md) | Lead-leg slice |
| 11 | [Jumping jack](iterations/11_jumping_jack.md) | Full-body bilateral slice |
| 12 | [Detailed set summary](iterations/12_set_summary.md) | Timeline/scores |
| 13 | [Workout comparison](iterations/13_workout_comparison.md) | Multi-set workout |
| 14 | [Local history](iterations/14_local_history.md) | Durable summary journal |
| 15 | [Core analytics](iterations/15_core_analytics.md) | Trends and drill-down |
| 16 | [Analytics insights](iterations/16_analytics_insights.md) | Improvements and records |
| 17 | [Guided demo](iterations/17_guided_demo.md) | Five observed guidance cycles |
| 18 | [Checkpoint TTS](iterations/18_checkpoint_tts.md) | Pre/mid/post coaching |
| 19 | [Cues and controls](iterations/19_cues_controls.md) | Deduplicated haptic/audio |
| 20 | [Release hardening](iterations/20_release_hardening.md) | Device-tested release |

## Cut line

Any passing iteration is shippable. Exercise priority: Squat, Bicep Curl, Lateral Raise, Shoulder Press, Reverse Lunge, Jumping Jack. Analytics starts only after reliable summaries and workout snapshots exist.
