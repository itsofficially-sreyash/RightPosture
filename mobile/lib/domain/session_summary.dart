import 'models.dart';

SessionSummary summarizeSession(List<Rep> reps) {
  final evaluated = reps
      .where((rep) => rep.status != RepStatus.calibrating)
      .toList(growable: false);
  final degraded = evaluated
      .where((rep) => rep.status == RepStatus.degraded)
      .toList(growable: false);
  final jointCounts = <String, int>{};
  for (final rep in degraded) {
    final joint = rep.responsibleJoint;
    if (joint != null) jointCounts[joint] = (jointCounts[joint] ?? 0) + 1;
  }
  String? primaryJoint;
  var primaryCount = 0;
  for (final entry in jointCounts.entries) {
    if (entry.value > primaryCount) {
      primaryJoint = entry.key;
      primaryCount = entry.value;
    }
  }

  return SessionSummary(
    totalReps: reps.length,
    formScorePercent: evaluated.isEmpty
        ? null
        : evaluated.where((rep) => rep.status == RepStatus.good).length /
              evaluated.length *
              100,
    degradationStartRep: degraded.isEmpty ? null : degraded.first.number,
    primaryResponsibleJoint: primaryJoint,
    repChecklist: List.unmodifiable(reps),
  );
}
