# App flow

```text
Launch
  -> Onboarding / Exercise Select
  -> First-visit Guided Demo (when incomplete or replayed)
  -> Exercise Setup and Camera Guidance
  -> Stable placement auto-starts 3-2-1 Countdown
  -> Calibration and Live Session
  -> Set Summary
       -> Next Set
       -> Change Exercise
       -> Finish Workout -> Workout Summary

Exercise Select / Workout Summary
  -> History and Analytics
  -> Exercise History
  -> Day Journal or Trend
  -> Session Journal Entry
```

All exercises share one screen/controller flow. Profiles and detectors supply exercise behavior. Analytics reads persisted immutable summaries only; never camera/pose streams.

## Navigation rules

- Unfinished exercises remain hidden.
- Back/cancel during setup/countdown records nothing.
- Next Set resets live engines but preserves workout/history.
- Change Exercise preserves completed sets.
- Finish Workout persists one summary snapshot.
- Analytics filters raw movement metrics by exercise.
- First exercise visit opens Guided Demo; later visits skip it after persisted completion.
- Guided Demo runs automatically, pauses on pose loss, and requires five fresh posture checks.
- Replay Demo is available from the matching exercise card.

## Explicitly absent

Mode selection, login/profile, cloud sync, social leaderboard, trainer marketplace, retained camera playback, clinical dashboard.
