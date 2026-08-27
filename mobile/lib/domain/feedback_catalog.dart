import 'exercise.dart';
import 'models.dart';

RepIssue? selectPrimaryIssue(Iterable<RepIssue> issues) {
  RepIssue? selected;
  var selectedPriority = -1;
  for (final issue in issues) {
    final priority = switch (issue.direction) {
      IssueDirection.belowRange || IssueDirection.aboveRange => 3,
      IssueDirection.asymmetric => 2,
      _ => 1,
    };
    if (selected == null ||
        priority > selectedPriority ||
        (priority == selectedPriority &&
            issue.normalizedSeverity > selected.normalizedSeverity)) {
      selected = issue;
      selectedPriority = priority;
    }
  }
  return selected;
}

String? feedbackForRep(Rep rep) {
  final issue = selectPrimaryIssue(rep.issues);
  return issue == null ? null : feedbackForIssue(issue);
}

String feedbackForIssue(RepIssue issue) {
  if (issue.exercise == ExerciseId.squat &&
      issue.metric == MovementMetric.kneeAngle) {
    return switch (issue.direction) {
      IssueDirection.belowRange => 'Next rep: go lower',
      IssueDirection.aboveRange => 'Next rep: do not go as deep',
      IssueDirection.increased => 'Next rep: go slightly lower',
      IssueDirection.decreased => 'Next rep: do not go as deep',
      IssueDirection.asymmetric => 'Keep both knees moving evenly',
    };
  }
  return 'Your movement changed from your baseline';
}

String metricLabel(MovementMetric metric) => switch (metric) {
  MovementMetric.kneeAngle ||
  MovementMetric.leftKneeAngle ||
  MovementMetric.rightKneeAngle => 'Knee range',
  MovementMetric.leftHipAngle || MovementMetric.rightHipAngle => 'Hip range',
  MovementMetric.leftElbowAngle ||
  MovementMetric.rightElbowAngle => 'Elbow range',
  MovementMetric.torsoLean => 'Torso position',
  MovementMetric.armElevation => 'Arm elevation',
  MovementMetric.stanceWidth => 'Stance width',
  MovementMetric.wristHeightSymmetry => 'Arm symmetry',
  MovementMetric.ankleHeightSymmetry => 'Leg symmetry',
};
