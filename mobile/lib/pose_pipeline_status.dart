import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'pose_pipeline.dart';
import 'domain/exercise.dart';

class PosePipelineStatusPanel extends StatelessWidget {
  const PosePipelineStatusPanel({
    super.key,
    required this.snapshot,
    required this.onRetry,
    this.onOpenSettings,
    this.showDiagnostics = kDebugMode,
    this.exercise = ExerciseId.squat,
  });

  final PosePipelineSnapshot snapshot;
  final VoidCallback onRetry;
  final VoidCallback? onOpenSettings;
  final bool showDiagnostics;
  final ExerciseId exercise;

  @override
  Widget build(BuildContext context) {
    if (snapshot.status == PosePipelineStatus.initializing) {
      return Semantics(
        label: 'Initializing camera',
        liveRegion: true,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (snapshot.status == PosePipelineStatus.failed) {
      final permissionDenied =
          snapshot.failureKind == PosePipelineFailureKind.permissionDenied;
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                permissionDenied
                    ? 'Camera permission is required to track your posture. '
                          'Allow camera access in Android settings, then try again.'
                    : snapshot.error ?? 'Camera failed',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (permissionDenied && onOpenSettings != null) ...[
                FilledButton(
                  key: const Key('open_app_settings'),
                  onPressed: onOpenSettings,
                  child: const Text('Open settings'),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }
    final guidance = switch (snapshot.status) {
      PosePipelineStatus.noPerson => 'Step into frame',
      PosePipelineStatus.lowConfidence => 'Show your full body',
      _ => 'Pose ready',
    };
    var diagnostics = '';
    if (exercise == ExerciseId.bicepCurl && snapshot.bicepCurlSample != null) {
      final sample = snapshot.bicepCurlSample!;
      diagnostics =
          '\nElbows: ${sample.leftElbowAngle.toStringAsFixed(1)}\u00b0 / '
          '${sample.rightElbowAngle.toStringAsFixed(1)}\u00b0';
    } else if ((exercise == ExerciseId.lateralRaise ||
            exercise == ExerciseId.shoulderPress) &&
        snapshot.lateralRaiseSample != null) {
      final sample = snapshot.lateralRaiseSample!;
      diagnostics =
          '\nElevation: ${sample.leftArmElevation.toStringAsFixed(1)}\u00b0 / '
          '${sample.rightArmElevation.toStringAsFixed(1)}\u00b0';
    } else if (snapshot.squatCandidate != null) {
      final candidate = snapshot.squatCandidate!;
      diagnostics =
          '\nKnee: ${candidate.kneeAngle.toStringAsFixed(1)}\u00b0'
          ' (${candidate.side})\n'
          'Confidence: ${(candidate.confidence * 100).toStringAsFixed(0)}%';
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Text(
          showDiagnostics
              ? '$guidance\nFrames: ${snapshot.processedFrames}\n'
                    'Last: ${snapshot.processingTime.inMilliseconds} ms'
                    '$diagnostics'
              : guidance,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
