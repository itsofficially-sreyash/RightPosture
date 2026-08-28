import 'feedback_catalog.dart';
import 'exercise.dart';
import 'models.dart';

SessionSummary summarizeSession(
  List<Rep> reps, {
  ExerciseId exercise = ExerciseId.squat,
}) {
  final evaluated = reps
      .where((rep) => rep.status != RepStatus.calibrating)
      .toList(growable: false);
  final degraded = evaluated
      .where((rep) => rep.status == RepStatus.degraded)
      .toList(growable: false);
  final jointCounts = <String, int>{};
  for (final rep in degraded) {
    final issue = selectPrimaryIssue(rep.issues);
    if (issue != null) {
      final label = metricLabel(issue.metric);
      jointCounts[label] = (jointCounts[label] ?? 0) + 1;
    }
  }
  String? primaryJoint;
  var primaryCount = 0;
  for (final entry in jointCounts.entries) {
    if (entry.value > primaryCount) {
      primaryJoint = entry.key;
      primaryCount = entry.value;
    }
  }

  final scored = evaluated.map(_repScore).toList(growable: false);
  final metricReps = evaluated
      .where((rep) => rep.metrics != null)
      .toList(growable: false);
  final tempo = metricReps
      .map((rep) => rep.metrics!.totalDuration.inMilliseconds / 1000)
      .toList(growable: false);
  final returns = metricReps
      .map((rep) => rep.metrics!.returnDuration.inMilliseconds / 1000)
      .toList(growable: false);
  final confidence = metricReps
      .map((rep) => rep.metrics!.completionConfidence * 100)
      .toList(growable: false);
  final symmetry = metricReps
      .map((rep) => rep.metrics!.bilateralTimingDifference)
      .whereType<Duration>()
      .map((duration) => duration.inMilliseconds / 1000)
      .toList(growable: false);
  final ranges = metricReps
      .map((rep) => rep.metrics!.rangeOfMotion.values)
      .where((values) => values.isNotEmpty)
      .map((values) => values.reduce((a, b) => a + b) / values.length)
      .toList(growable: false);
  final componentScores = [
    _component('range', 'Range consistency', ranges),
    _component('tempo', 'Tempo consistency', tempo),
    _component('control', 'Control / return consistency', returns),
    ComponentScore(
      id: 'symmetry',
      label: 'Left / right symmetry',
      percent: symmetry.length < 2
          ? null
          : (100 - (_average(symmetry)! / (_average(tempo) ?? 1) * 100)).clamp(
              0,
              100,
            ),
      evaluatedRepCount: symmetry.length,
    ),
    ComponentScore(
      id: 'exercise',
      label: _exerciseComponentLabel(exercise),
      percent: evaluated.length < 2 ? null : _average(scored)! * 100,
      evaluatedRepCount: evaluated.length,
    ),
  ];
  final availableComponents = componentScores
      .map((component) => component.percent)
      .whereType<double>()
      .toList(growable: false);
  final ordered = [...evaluated]
    ..sort((a, b) => _repScore(b).compareTo(_repScore(a)));

  return SessionSummary(
    totalReps: reps.length,
    formScorePercent: evaluated.length < 2 ? null : _average(scored)! * 100,
    degradationStartRep: degraded.isEmpty ? null : degraded.first.number,
    primaryResponsibleJoint: primaryJoint,
    repChecklist: List.unmodifiable(reps),
    componentScores: componentScores,
    averageTempoSeconds: _average(tempo),
    averageReturnSeconds: _average(returns),
    averageConfidencePercent: _average(confidence),
    averageSymmetrySeconds: _average(symmetry),
    consistencyScorePercent: availableComponents.isEmpty
        ? null
        : _average(availableComponents),
    bestRepNumber: ordered.isEmpty ? null : ordered.first.number,
    lowestRepNumber: ordered.isEmpty ? null : ordered.last.number,
    goodRepCount: evaluated.where((rep) => rep.status == RepStatus.good).length,
    warningRepCount: evaluated
        .where((rep) => rep.status == RepStatus.warning)
        .length,
    degradedRepCount: degraded.length,
    calibrationRepCount: reps
        .where((rep) => rep.status == RepStatus.calibrating)
        .length,
  );
}

double _repScore(Rep rep) => switch (rep.status) {
  RepStatus.good => 1,
  RepStatus.warning => 0.5,
  RepStatus.degraded || RepStatus.calibrating => 0,
};

double? _average(Iterable<double> values) {
  if (values.isEmpty) return null;
  return values.reduce((a, b) => a + b) / values.length;
}

ComponentScore _component(String id, String label, List<double> values) =>
    ComponentScore(
      id: id,
      label: label,
      percent: _consistency(values),
      evaluatedRepCount: values.length,
    );

double? _consistency(List<double> values) {
  if (values.length < 2) return null;
  final mean = _average(values)!;
  if (mean == 0) return values.every((value) => value == 0) ? 100 : null;
  final deviation =
      values.map((value) => (value - mean).abs()).reduce((a, b) => a + b) /
      values.length;
  return (100 - deviation / mean.abs() * 100).clamp(0, 100);
}

String _exerciseComponentLabel(ExerciseId exercise) => switch (exercise) {
  ExerciseId.squat => 'Depth consistency',
  ExerciseId.bicepCurl => 'Curl range consistency',
  ExerciseId.lateralRaise => 'Elevation consistency',
  ExerciseId.shoulderPress => 'Overhead completion',
  ExerciseId.reverseLunge => 'Lead-leg range consistency',
  ExerciseId.jumpingJack => 'Arm and stance coordination',
};
