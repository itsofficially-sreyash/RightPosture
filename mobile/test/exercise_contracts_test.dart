import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/bicep_curl_rep_detector.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/exercise_registry.dart';
import 'package:right_posture/domain/lateral_raise_rep_detector.dart';
import 'package:right_posture/domain/squat_rep_detector.dart';
import 'package:right_posture/domain/shoulder_press_rep_detector.dart';

void main() {
  test('registry exposes squat profile and detector', () {
    const registry = ExerciseRegistry();

    expect(registry.profileFor(ExerciseId.squat), same(squatExerciseProfile));
    expect(registry.detectorFor(ExerciseId.squat), isA<SquatRepDetector>());
  });

  test('squat detector consumes shared movement frames', () {
    final detector = const ExerciseRegistry().detectorFor(ExerciseId.squat);
    RepCompletion? completion;
    final start = DateTime(2026);
    for (final (index, angle) in [170.0, 145.0, 165.0].indexed) {
      completion =
          detector.addFrame(
            MovementFrame(
              timestamp: start.add(Duration(seconds: index)),
              values: {MovementMetric.kneeAngle: angle},
              confidence: {MovementMetric.kneeAngle: index == 1 ? 0.8 : 0.9},
              trackedSide: TrackedSide.left,
            ),
          ) ??
          completion;
    }

    expect(completion, isNotNull);
    expect(completion!.minimumValues[MovementMetric.kneeAngle], 145);
    expect(completion.maximumValues[MovementMetric.kneeAngle], 170);
    expect(completion.trackedSide, TrackedSide.left);
    expect(completion.metrics.totalDuration, const Duration(seconds: 2));
    expect(completion.metrics.outwardDuration, const Duration(seconds: 1));
    expect(completion.metrics.returnDuration, const Duration(seconds: 1));
    expect(completion.metrics.rangeOfMotion[MovementMetric.kneeAngle], 25);
    expect(completion.metrics.completionConfidence, 0.8);
    expect(completion.metrics.bilateralTimingDifference, isNull);
  });

  test('low-confidence gap invalidates active rep timing', () {
    final detector = const ExerciseRegistry().detectorFor(ExerciseId.squat);
    final start = DateTime(2026);

    RepCompletion? add(int seconds, double angle, double confidence) =>
        detector.addFrame(
          MovementFrame(
            timestamp: start.add(Duration(seconds: seconds)),
            values: {MovementMetric.kneeAngle: angle},
            confidence: {MovementMetric.kneeAngle: confidence},
            trackedSide: TrackedSide.left,
          ),
        );

    expect(add(0, 170, 0.9), isNull);
    expect(add(1, 140, 0.9), isNull);
    expect(add(10, 140, 0.2), isNull);
    expect(add(11, 165, 0.9), isNull);
  });

  test('out-of-order timestamps cannot produce negative durations', () {
    final detector = const ExerciseRegistry().detectorFor(ExerciseId.squat);
    final start = DateTime(2026);
    RepCompletion? completion;
    for (final (seconds, angle) in [(2, 170.0), (1, 140.0), (0, 165.0)]) {
      completion = detector.addFrame(
        MovementFrame(
          timestamp: start.add(Duration(seconds: seconds)),
          values: {MovementMetric.kneeAngle: angle},
          confidence: const {MovementMetric.kneeAngle: 0.9},
          trackedSide: TrackedSide.left,
        ),
      );
    }

    expect(completion!.metrics.totalDuration, Duration.zero);
    expect(completion.metrics.outwardDuration, Duration.zero);
    expect(completion.metrics.returnDuration, Duration.zero);
  });

  test('unfinished exercises remain unavailable', () {
    const registry = ExerciseRegistry();

    expect(
      () => registry.detectorFor(ExerciseId.reverseLunge),
      throwsUnsupportedError,
    );
  });

  test('registry exposes hidden bicep curl domain slice', () {
    const registry = ExerciseRegistry();

    expect(
      registry.profileFor(ExerciseId.bicepCurl),
      same(bicepCurlExerciseProfile),
    );
    expect(
      registry.detectorFor(ExerciseId.bicepCurl),
      isA<BicepCurlRepDetector>(),
    );
  });

  test('registry exposes hidden lateral raise domain slice', () {
    const registry = ExerciseRegistry();

    expect(
      registry.profileFor(ExerciseId.lateralRaise),
      same(lateralRaiseExerciseProfile),
    );
    expect(
      registry.detectorFor(ExerciseId.lateralRaise),
      isA<LateralRaiseRepDetector>(),
    );
  });

  test('registry exposes hidden shoulder press domain slice', () {
    const registry = ExerciseRegistry();

    expect(
      registry.profileFor(ExerciseId.shoulderPress),
      same(shoulderPressExerciseProfile),
    );
    expect(
      registry.detectorFor(ExerciseId.shoulderPress),
      isA<ShoulderPressRepDetector>(),
    );
  });
}
