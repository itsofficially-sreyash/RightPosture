import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/exercise_registry.dart';
import 'package:right_posture/domain/squat_rep_detector.dart';

void main() {
  test('registry exposes squat profile and detector', () {
    const registry = ExerciseRegistry();

    expect(registry.profileFor(ExerciseId.squat), same(squatExerciseProfile));
    expect(registry.detectorFor(ExerciseId.squat), isA<SquatRepDetector>());
  });

  test('squat detector consumes shared movement frames', () {
    final detector = const ExerciseRegistry().detectorFor(ExerciseId.squat);
    RepCompletion? completion;
    for (final angle in [170.0, 145.0, 165.0]) {
      completion =
          detector.addFrame(
            MovementFrame(
              timestamp: DateTime(2026),
              values: {MovementMetric.kneeAngle: angle},
              confidence: const {MovementMetric.kneeAngle: 0.9},
              trackedSide: TrackedSide.left,
            ),
          ) ??
          completion;
    }

    expect(completion, isNotNull);
    expect(completion!.minimumValues[MovementMetric.kneeAngle], 145);
    expect(completion.maximumValues[MovementMetric.kneeAngle], 170);
    expect(completion.trackedSide, TrackedSide.left);
  });

  test('unfinished exercises remain unavailable', () {
    const registry = ExerciseRegistry();

    expect(
      () => registry.detectorFor(ExerciseId.bicepCurl),
      throwsUnsupportedError,
    );
  });
}
