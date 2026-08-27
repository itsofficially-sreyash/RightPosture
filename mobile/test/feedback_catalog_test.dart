import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/feedback_catalog.dart';
import 'package:right_posture/domain/models.dart';

void main() {
  RepIssue issue({
    MovementMetric metric = MovementMetric.kneeAngle,
    IssueDirection direction = IssueDirection.increased,
    double severity = 1,
  }) => RepIssue(
    exercise: ExerciseId.squat,
    metric: metric,
    direction: direction,
    measuredValue: 120,
    normalizedSeverity: severity,
  );

  test('range issue outranks a stronger baseline deviation', () {
    final selected = selectPrimaryIssue([
      issue(severity: 5),
      issue(direction: IssueDirection.belowRange, severity: 1),
    ]);

    expect(selected!.direction, IssueDirection.belowRange);
  });

  test('strongest issue wins within the same priority', () {
    final selected = selectPrimaryIssue([
      issue(severity: 1),
      issue(direction: IssueDirection.decreased, severity: 2),
    ]);

    expect(selected!.direction, IssueDirection.decreased);
  });

  test('supported squat issue has deterministic actionable copy', () {
    expect(
      feedbackForIssue(issue(direction: IssueDirection.belowRange)),
      'Next rep: go lower',
    );
  });

  test('unsupported metric uses safe human fallback', () {
    final feedback = feedbackForIssue(issue(metric: MovementMetric.torsoLean));

    expect(feedback, 'Your movement changed from your baseline');
    expect(feedback, isNot(contains('torsoLean')));
  });
}
