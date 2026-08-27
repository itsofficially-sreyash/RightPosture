# Execution Plans

Plans are ordered, small, and independently verifiable. Finish one iteration, update `progress.md`, then start the next. Do not implement later-iteration scaffolding early.

## Approval gate

These plans are drafts. No implementation begins until the user approves them and resolves the decision list in `progress.md`.

## Working rules

- P0 before P1; squat before lunge.
- Reuse Flutter/Dart and installed packages; add no speculative dependencies.
- Keep UI, session logic, and camera/ML services separate, but create no interface or abstraction until two consumers require it.
- Each non-trivial logic change gets the smallest runnable test that proves it.
- Hardware truth overrides assumptions in planning docs.
- Update `progress.md` after every iteration.
- After every completed iteration, provide a Conventional Commit message. Do not run `git commit` unless the user explicitly requests it.
