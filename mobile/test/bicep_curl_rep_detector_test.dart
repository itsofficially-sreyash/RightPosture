import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/bicep_curl_rep_detector.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/feedback_catalog.dart';
import 'package:right_posture/domain/models.dart';
import 'package:right_posture/domain/rep_evaluator.dart';

void main() {
  final start = DateTime(2026);

  MovementFrame frame(
    int milliseconds,
    double left,
    double right, {
    double confidence = 0.9,
    double torsoPosition = 1,
  }) => MovementFrame(
    timestamp: start.add(Duration(milliseconds: milliseconds)),
    values: {
      MovementMetric.leftElbowAngle: left,
      MovementMetric.rightElbowAngle: right,
      MovementMetric.torsoVerticalPosition: torsoPosition,
    },
    confidence: {
      MovementMetric.leftElbowAngle: confidence,
      MovementMetric.rightElbowAngle: confidence,
      MovementMetric.torsoVerticalPosition: confidence,
    },
    trackedSide: TrackedSide.bilateral,
  );

  test('simultaneous curl completes once with bilateral metrics', () {
    final detector = BicepCurlRepDetector();
    RepCompletion? completion;
    for (final sample in [
      frame(0, 165, 165),
      frame(500, 120, 125),
      frame(1000, 55, 60, confidence: 0.8),
      frame(1500, 120, 125),
      frame(2000, 165, 165),
    ]) {
      completion = detector.addFrame(sample) ?? completion;
    }

    expect(completion, isNotNull);
    expect(completion!.trackedSide, TrackedSide.bilateral);
    expect(completion.minimumValues[MovementMetric.leftElbowAngle], 55);
    expect(
      completion.metrics.rangeOfMotion[MovementMetric.leftElbowAngle],
      110,
    );
    expect(completion.metrics.totalDuration, const Duration(seconds: 2));
    expect(completion.metrics.completionConfidence, 0.8);
    expect(completion.metrics.bilateralTimingDifference, Duration.zero);
  });

  test('standing duplicates do not count and partial curl completes', () {
    final detector = BicepCurlRepDetector();
    for (var i = 0; i < 8; i++) {
      expect(detector.addFrame(frame(i * 100, 165, 165)), isNull);
    }

    expect(detector.addFrame(frame(1000, 135, 137)), isNull);
    final completion = detector.addFrame(frame(1500, 165, 165));

    expect(completion, isNotNull);
    expect(completion!.minimumValues[MovementMetric.leftElbowAngle], 135);
  });

  test('both arms must return before simultaneous rep completes', () {
    final detector = BicepCurlRepDetector();
    detector.addFrame(frame(0, 165, 165));
    detector.addFrame(frame(500, 80, 80));

    expect(detector.addFrame(frame(1000, 165, 120)), isNull);
    expect(detector.addFrame(frame(1500, 165, 165)), isNotNull);
  });

  test('low-confidence gap invalidates active curl', () {
    final detector = BicepCurlRepDetector();
    detector.addFrame(frame(0, 165, 165));
    detector.addFrame(frame(500, 90, 90));
    detector.addFrame(frame(1000, 90, 90, confidence: 0.2));

    expect(detector.addFrame(frame(1500, 165, 165)), isNull);
  });

  test('squat-like torso movement invalidates curl attempt', () {
    final detector = BicepCurlRepDetector();
    detector.addFrame(frame(0, 165, 165));
    detector.addFrame(frame(500, 100, 100, torsoPosition: 1.6));

    expect(detector.addFrame(frame(1000, 165, 165)), isNull);
    expect(detector.phase, BicepCurlPhase.curling);
  });

  test('partial curl receives exercise-specific range feedback', () {
    final evaluator = RepEvaluator(
      ExerciseThresholds(
        joints: const {
          'left': JointThreshold(
            minimum: 0,
            maximum: 130,
            deviationThreshold: 20,
          ),
          'right': JointThreshold(
            minimum: 0,
            maximum: 130,
            deviationThreshold: 20,
          ),
        },
      ),
      exercise: ExerciseId.bicepCurl,
      metrics: const {
        'left': MovementMetric.leftElbowAngle,
        'right': MovementMetric.rightElbowAngle,
      },
    );
    for (var i = 0; i < 3; i++) {
      evaluator.evaluate({'left': 80, 'right': 80}, confidenceOk: true);
    }

    final rep = evaluator.evaluate({
      'left': 140,
      'right': 140,
    }, confidenceOk: true)!;

    expect(rep.status, RepStatus.degraded);
    expect(feedbackForRep(rep), 'Curl through a little more range');
  });
}
