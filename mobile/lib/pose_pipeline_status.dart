import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'pose_pipeline.dart';

class PosePipelineStatusPanel extends StatelessWidget {
  const PosePipelineStatusPanel({
    super.key,
    required this.snapshot,
    required this.onRetry,
    this.showDiagnostics = kDebugMode,
  });

  final PosePipelineSnapshot snapshot;
  final VoidCallback onRetry;
  final bool showDiagnostics;

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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                snapshot.error ?? 'Camera failed',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
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
    final candidate = snapshot.squatCandidate;
    final diagnostics = candidate == null
        ? ''
        : '\nKnee: ${candidate.kneeAngle.toStringAsFixed(1)}\u00b0'
              ' (${candidate.side})\n'
              'Confidence: ${(candidate.confidence * 100).toStringAsFixed(0)}%';
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
