import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/guided_demo.dart';
import 'package:right_posture/domain/squat_rep_detector.dart';
import 'package:right_posture/ui/guided_demo_page.dart';

void main() {
  test('demo releases camera before opening exercise setup', () async {
    final events = <String>[];

    await finishGuidedDemoTransition(
      closeCamera: () async => events.add('camera closed'),
      persistVisit: () async => events.add('visit saved'),
    );

    expect(events, ['camera closed', 'visit saved']);
  });

  test('demo completes only after five detected exercise reps', () {
    final tracker = GuidedDemoRepTracker(SquatRepDetector());
    final start = DateTime(2026, 8, 29, 12);

    var frame = 0;
    bool accept(double angle) {
      frame++;
      return tracker.accept(
        frame: frame,
        movement: MovementFrame(
          timestamp: start.add(Duration(milliseconds: frame * 100)),
          values: {MovementMetric.kneeAngle: angle},
          confidence: const {MovementMetric.kneeAngle: 1},
          trackedSide: TrackedSide.left,
        ),
      );
    }

    expect(accept(165), isFalse);
    for (var rep = 1; rep <= 5; rep++) {
      expect(accept(100), isFalse);
      expect(accept(165), isTrue);
      expect(tracker.completedReps, rep);
    }

    expect(tracker.isComplete, isTrue);
    expect(
      tracker.accept(
        frame: frame,
        movement: MovementFrame(
          timestamp: start,
          values: const {MovementMetric.kneeAngle: 100},
          confidence: const {MovementMetric.kneeAngle: 1},
          trackedSide: TrackedSide.left,
        ),
      ),
      isFalse,
    );
  });

  test('squat guidance uses knee angle only', () {
    expect(
      guidedDemoInstruction(ExerciseId.squat, {MovementMetric.kneeAngle: 130}),
      contains('Straighten your knees'),
    );
    expect(
      guidedDemoInstruction(ExerciseId.squat, {
        MovementMetric.leftElbowAngle: 90,
      }),
      isNull,
    );
  });

  test('bilateral guidance responds to measured asymmetry', () {
    expect(
      guidedDemoInstruction(ExerciseId.bicepCurl, {
        MovementMetric.leftElbowAngle: 160,
        MovementMetric.rightElbowAngle: 120,
      }),
      contains('same position'),
    );
    expect(
      guidedDemoInstruction(ExerciseId.lateralRaise, {
        MovementMetric.leftArmElevation: 10,
        MovementMetric.rightArmElevation: 40,
      }),
      contains('same height'),
    );
    expect(
      guidedDemoInstruction(ExerciseId.shoulderPress, {
        MovementMetric.leftArmElevation: 140,
        MovementMetric.rightArmElevation: 140,
      }),
      contains('shoulder height'),
    );
  });

  test('unimplemented exercises generate no demo instruction', () {
    expect(
      guidedDemoInstruction(ExerciseId.reverseLunge, {
        MovementMetric.leftKneeAngle: 90,
      }),
      isNull,
    );
    expect(
      guidedDemoInstruction(ExerciseId.jumpingJack, {
        MovementMetric.leftArmElevation: 90,
      }),
      isNull,
    );
  });
}
