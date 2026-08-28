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
  if (issue.exercise == ExerciseId.bicepCurl &&
      (issue.metric == MovementMetric.leftElbowAngle ||
          issue.metric == MovementMetric.rightElbowAngle)) {
    return switch (issue.direction) {
      IssueDirection.belowRange ||
      IssueDirection.increased => 'Curl through a little more range',
      IssueDirection.asymmetric => 'Move both arms together',
      _ => 'Keep your curl range consistent',
    };
  }
  if (issue.exercise == ExerciseId.lateralRaise &&
      (issue.metric == MovementMetric.leftArmElevation ||
          issue.metric == MovementMetric.rightArmElevation)) {
    return switch (issue.direction) {
      IssueDirection.aboveRange ||
      IssueDirection.decreased => 'Raise both arms a little higher',
      IssueDirection.asymmetric => 'Lift both arms evenly',
      _ => 'Keep your raise height consistent',
    };
  }
  if (issue.exercise == ExerciseId.shoulderPress &&
      (issue.metric == MovementMetric.leftArmElevation ||
          issue.metric == MovementMetric.rightArmElevation ||
          issue.metric == MovementMetric.leftElbowAngle ||
          issue.metric == MovementMetric.rightElbowAngle)) {
    return issue.direction == IssueDirection.asymmetric
        ? 'Press both arms evenly'
        : 'Press both hands fully overhead';
  }
  if (issue.exercise == ExerciseId.lateralRaise &&
      (issue.metric == MovementMetric.leftElbowAngle ||
          issue.metric == MovementMetric.rightElbowAngle)) {
    return issue.direction == IssueDirection.asymmetric
        ? 'Keep both elbows even'
        : 'Keep your elbow bend consistent';
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
  MovementMetric.torsoVerticalPosition => 'Torso movement',
  MovementMetric.armElevation => 'Arm elevation',
  MovementMetric.leftArmElevation ||
  MovementMetric.rightArmElevation => 'Arm elevation',
  MovementMetric.stanceWidth => 'Stance width',
  MovementMetric.wristHeightSymmetry => 'Arm symmetry',
  MovementMetric.ankleHeightSymmetry => 'Leg symmetry',
};
