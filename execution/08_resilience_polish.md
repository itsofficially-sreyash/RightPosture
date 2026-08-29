# Iteration 08 — Resilience and P1 Polish

## Status

Software complete on 2026-08-27. Hardware permission and lifecycle checks remain pending.

## Goal

Protect live demo, then add only cheap polish that does not hurt camera performance.

## Scope, in order

1. Permission-denied explanation and retry/settings path.
2. Camera initialization failure with retry.
3. No-person and low-confidence overlays.
4. Unexpected-session-error recovery.
5. Single onboarding/permission screen.
6. Rep pulse, status crossfade, progress animation, and summary entrance.
7. Optional degraded-rep audio/haptic cue if native Flutter/platform support is sufficient.

## Cut rule

Cut animation, audio, onboarding, and session history before touching stable P0 behavior. Do not add new packages for cosmetic effects.

## Checks

- Deny/grant permission paths on device.
- Background/foreground app during live session.
- Repeated start/end/restart cycles.
- Re-run live performance check after each animation group.
- Accessibility labels, contrast, text scaling, and touch targets.

## Exit gate

No known demo-path crash. P1 additions cause no visible pose/preview regression.

Automated software gate passed. Device-only denial/grant, settings return, background/foreground, and repeated-session checks remain user-owned.
