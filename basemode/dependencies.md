# dependencies.md
Keep this list short — every added package is a Green Light setup-risk in a 19-hour build.

## Core (locked)
- `google_mlkit_pose_detection` (flipped from `flutter_pose_detection`, decision.md D3) — pose landmarks only, no angle helpers, no confirmed NPU delegate. Mature, well-documented, MIT licensed, ~150 pub points. UNVERIFIED on the specific iQOO loaner hardware until execution/01_verify_hardware.md passes — the flip reduces package-risk but doesn't eliminate device-specific risk.
- `camera` — camera feed access, well-established Flutter package, low risk.
- `flutter_riverpod` — state management, per user lock.

## Conditional / fallback
- None currently defined. Previously `google_mlkit_pose_detection` was the fallback for `flutter_pose_detection`; now that it's primary, there is no fallback package identified if it fails hardware verification. If execution/01_verify_hardware.md fails, this is a blocking decision, not an automatic swap.

## Explicitly not adding
- No backend/HTTP client package — no backend planned (tech_stack.md).
- No local DB package (`sqflite`, `hive`, etc.) — no persistence in MVP scope (prd.md, data_model.md).
- No PDF/export package unless P2 "export summary" feature is reached (features.md) — don't pre-install for a feature that may not get built.

## Before adding anything not listed here
Ask: does this serve a P0 or P1 feature (features.md)? If it only serves a P2/cut feature, don't add it — every unplanned dependency risks a Green Light setup failure eating into build time.
