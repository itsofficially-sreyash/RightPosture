# Iteration 02 — Camera/Pose Integration Spike

## Goal

Build camera-to-ML Kit integration and prove its pure logic and Android compilation. Physical-device behavior is verified by the user when hardware becomes available.

## Scope

- Request camera permission and initialize one camera.
- Stream frames to ML Kit using the correct image format, rotation, and metadata.
- Process at most one frame at a time; drop incoming frames while detector is busy.
- Draw a minimal landmark/skeleton overlay with correct preview coordinate mapping and mirroring.
- Show a small diagnostic readout: detection present, processed-frame count, and rough processing time.
- Test person entering/leaving frame and app lifecycle pause/resume.

## Not in scope

- Production UI, Riverpod graph, rep counting, evaluation, summary, animations, or threshold tuning.

## Automated checks

- No concurrent detector calls or growing frame backlog.
- Rotation compensation has unit coverage.
- Analyzer, tests, and Android debug build pass.

## User-owned hardware checklist

- Runs on Android/iQOO without crash for 2 minutes.
- Overlay follows body with correct orientation and acceptable visual latency.
- Person entering/leaving frame updates detection status.
- Camera and detector dispose and resume cleanly after background/foreground.
- Permission denial and retry remain usable.

## Exit gate

Automated checks pass. Hardware status remains explicitly unverified until the user reports results; any device failure becomes a fix before release rather than a false pass.
