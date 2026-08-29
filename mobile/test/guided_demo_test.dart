import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/guided_demo.dart';
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

  test('five cycles require fresh frames and spacing', () {
    final tracker = GuidedDemoCycleTracker();
    final start = DateTime(2026, 8, 29, 12);

    expect(
      tracker.accept(frame: 1, checkedAt: start, instruction: 'First check'),
      'First check',
    );
    expect(
      tracker.accept(
        frame: 1,
        checkedAt: start.add(const Duration(seconds: 2)),
        instruction: 'Same frame',
      ),
      isNull,
    );
    expect(
      tracker.accept(
        frame: 2,
        checkedAt: start.add(const Duration(seconds: 1)),
        instruction: 'Too soon',
      ),
      isNull,
    );
    expect(
      tracker.accept(
        frame: 2,
        checkedAt: start.add(const Duration(seconds: 2)),
        instruction: null,
      ),
      isNull,
    );
    for (var cycle = 2; cycle <= 5; cycle++) {
      expect(
        tracker.accept(
          frame: cycle,
          checkedAt: start.add(Duration(seconds: cycle * 2)),
          instruction: 'Check $cycle',
        ),
        'Check $cycle',
      );
    }

    expect(tracker.completedCycles, 5);
    expect(tracker.isComplete, isTrue);
    expect(
      tracker.accept(
        frame: 6,
        checkedAt: start.add(const Duration(seconds: 12)),
        instruction: 'Extra',
      ),
      isNull,
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
