import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/checkpoint_tts.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/history.dart';
import 'package:right_posture/domain/models.dart';

void main() {
  test('midpoint uses target ceiling and explicit open-set fallback', () {
    final targeted = MidpointCheckpoint();
    expect(targeted.triggerRep(9), 5);
    expect(targeted.shouldFire(completedReps: 4, targetRepCount: 9), isFalse);
    expect(targeted.shouldFire(completedReps: 5, targetRepCount: 9), isTrue);
    expect(targeted.shouldFire(completedReps: 6, targetRepCount: 9), isFalse);

    final open = MidpointCheckpoint();
    expect(open.triggerRep(null), 5);
    expect(open.shouldFire(completedReps: 5), isTrue);
  });

  test('pre-set message uses same-exercise history only', () {
    final curl = historySet(
      exercise: ExerciseId.bicepCurl,
      feedback: ['Keep your curl range consistent'],
    );
    expect(
      preSetCheckpointMessage(ExerciseId.squat, [curl]),
      'Starting Squat. Keep each rep controlled and consistent.',
    );

    final squat = historySet(
      exercise: ExerciseId.squat,
      feedback: ['Next rep: go lower'],
    );
    expect(
      preSetCheckpointMessage(ExerciseId.squat, [curl, squat]),
      contains('Next rep: go lower'),
    );
  });

  test('mid-set correction requires repeated structured issue', () {
    final issue = RepIssue(
      exercise: ExerciseId.squat,
      metric: MovementMetric.kneeAngle,
      direction: IssueDirection.belowRange,
      measuredValue: 150,
      normalizedSeverity: 0.5,
    );
    final oneIssue = [
      rep(1, issues: [issue]),
    ];
    expect(
      midSetCheckpointMessage(ExerciseId.squat, oneIssue),
      isNot(contains('go lower')),
    );
    expect(
      midSetCheckpointMessage(ExerciseId.squat, [
        rep(1, issues: [issue]),
        rep(2, issues: [issue]),
      ]),
      contains('go lower'),
    );
  });

  test('good midpoint and post-set remain positive without invented issue', () {
    final reps = [rep(1), rep(2)];
    expect(
      midSetCheckpointMessage(ExerciseId.squat, reps),
      contains('form is steady'),
    );
    final summary = SessionSummary(
      totalReps: 2,
      formScorePercent: 100,
      degradationStartRep: null,
      primaryResponsibleJoint: null,
      repChecklist: reps,
      consistencyScorePercent: 95,
      goodRepCount: 2,
    );
    final message = postSetCheckpointMessage(ExerciseId.squat, summary, reps);
    expect(message, contains('Form Score 100 percent'));
    expect(message, contains('Keep your current form steady'));
    expect(message, isNot(contains('degradation')));
  });
}

Rep rep(int number, {List<RepIssue> issues = const []}) => Rep(
  number: number,
  angles: const {},
  status: issues.isEmpty ? RepStatus.good : RepStatus.warning,
  issues: issues,
);

HistorySet historySet({
  required ExerciseId exercise,
  List<String> feedback = const [],
}) => HistorySet(
  exercise: exercise,
  completedAt: DateTime(2026, 8, 29),
  totalReps: 5,
  goodReps: 5,
  warningReps: 0,
  degradedReps: 0,
  calibrationReps: 0,
  formScorePercent: 100,
  componentScores: const [],
  averageRange: null,
  averageTempoSeconds: null,
  averageSymmetrySeconds: null,
  consistencyScorePercent: null,
  degradationStartRep: null,
  issues: const [],
  feedback: feedback,
  repOutcomes: const [],
);
