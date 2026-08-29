import 'exercise.dart';
import 'exercise_registry.dart';
import 'feedback_catalog.dart';
import 'history.dart';
import 'models.dart';

enum SpokenFeedbackCheckpoint { preSet, midSet, postSet }

class SetPlan {
  const SetPlan({this.targetRepCount});

  final int? targetRepCount;
}

class MidpointCheckpoint {
  bool _fired = false;

  bool get fired => _fired;

  int triggerRep(int? targetRepCount) =>
      targetRepCount == null ? 5 : (targetRepCount / 2).ceil();

  bool shouldFire({required int completedReps, int? targetRepCount}) {
    if (_fired || completedReps < triggerRep(targetRepCount)) return false;
    _fired = true;
    return true;
  }
}

String preSetCheckpointMessage(
  ExerciseId exercise,
  Iterable<HistorySet> previousSets,
) {
  final name = const ExerciseRegistry().profileFor(exercise).displayName;
  final sets = previousSets.where((set) => set.exercise == exercise).toList()
    ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
  if (sets.isEmpty) {
    return 'Starting $name. Keep each rep controlled and consistent.';
  }
  final latest = sets.last;
  if (latest.feedback.isNotEmpty) {
    return 'For this $name set: ${latest.feedback.first}.';
  }
  if (latest.formScorePercent != null) {
    return 'Your latest $name Form Score was '
        '${latest.formScorePercent!.round()} percent. Keep your form steady.';
  }
  return 'Starting another $name set. Keep each rep controlled and consistent.';
}

String midSetCheckpointMessage(ExerciseId exercise, List<Rep> reps) {
  final issue = _persistentIssue(reps);
  if (issue != null) {
    return 'Mid-set check: ${feedbackForIssue(issue)}.';
  }
  final evaluated = reps.where((rep) => rep.status != RepStatus.calibrating);
  final positive =
      evaluated.isNotEmpty &&
      evaluated.every((rep) => rep.status == RepStatus.good);
  return positive
      ? 'Mid-set check: ${reps.length} reps complete. Your form is steady.'
      : 'Mid-set check: ${reps.length} reps complete. Continue with controlled reps.';
}

String postSetCheckpointMessage(
  ExerciseId exercise,
  SessionSummary summary,
  List<Rep> reps,
) {
  final parts = <String>['Set complete. ${summary.totalReps} reps.'];
  if (summary.formScorePercent != null) {
    parts.add('Form Score ${summary.formScorePercent!.round()} percent.');
  }
  if (summary.consistencyScorePercent != null) {
    parts.add(
      'Consistency ${summary.consistencyScorePercent!.round()} percent.',
    );
  }
  if (summary.degradationStartRep != null) {
    parts.add('Form degradation began at rep ${summary.degradationStartRep}.');
  }
  final issue = _persistentIssue(reps);
  parts.add(
    issue == null
        ? 'Keep your current form steady next set.'
        : 'Next set: ${feedbackForIssue(issue)}.',
  );
  return parts.join(' ');
}

RepIssue? _persistentIssue(List<Rep> reps) {
  final groups = <(MovementMetric, IssueDirection), List<RepIssue>>{};
  for (final issue in reps.expand((rep) => rep.issues)) {
    groups.putIfAbsent((issue.metric, issue.direction), () => []).add(issue);
  }
  final persistent = groups.entries.where((entry) => entry.value.length >= 2);
  if (persistent.isEmpty) return null;
  final ordered = persistent.toList()
    ..sort((a, b) {
      final count = b.value.length.compareTo(a.value.length);
      if (count != 0) return count;
      final aSeverity = a.value
          .map((issue) => issue.normalizedSeverity)
          .reduce((x, y) => x + y);
      final bSeverity = b.value
          .map((issue) => issue.normalizedSeverity)
          .reduce((x, y) => x + y);
      return bSeverity.compareTo(aSeverity);
    });
  return ordered.first.value.reduce(
    (a, b) => a.normalizedSeverity >= b.normalizedSeverity ? a : b,
  );
}
