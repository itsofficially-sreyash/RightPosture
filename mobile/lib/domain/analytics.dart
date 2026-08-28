import 'exercise.dart';
import 'history.dart';

enum AnalyticsMetric {
  formScore,
  rangeOfMotion,
  tempo,
  degradationPoint,
  symmetry,
  consistency,
}

class AnalyticsPoint {
  const AnalyticsPoint({required this.timestamp, required this.value});

  final DateTime timestamp;
  final double? value;
}

class WeeklyExerciseSummary {
  const WeeklyExerciseSummary({
    required this.sets,
    required this.reps,
    required this.averageFormScore,
  });

  final int sets;
  final int reps;
  final double? averageFormScore;
}

List<AnalyticsPoint> metricSeries(
  Iterable<HistoryWorkout> workouts,
  ExerciseId exercise,
  AnalyticsMetric metric,
) {
  final sets = historyForExercise(workouts, exercise)
    ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
  return sets
      .map(
        (set) => AnalyticsPoint(
          timestamp: set.completedAt,
          value: switch (metric) {
            AnalyticsMetric.formScore => set.formScorePercent,
            AnalyticsMetric.rangeOfMotion => set.averageRange,
            AnalyticsMetric.tempo => set.averageTempoSeconds,
            AnalyticsMetric.degradationPoint =>
              set.degradationStartRep?.toDouble(),
            AnalyticsMetric.symmetry => set.averageSymmetrySeconds,
            AnalyticsMetric.consistency => set.consistencyScorePercent,
          },
        ),
      )
      .toList(growable: false);
}

Map<MovementMetric, int> issueFrequency(
  Iterable<HistoryWorkout> workouts,
  ExerciseId exercise,
) {
  final result = <MovementMetric, int>{};
  for (final issue in historyForExercise(
    workouts,
    exercise,
  ).expand((set) => set.issues)) {
    result[issue.metric] = (result[issue.metric] ?? 0) + 1;
  }
  return result;
}

({int good, int warning, int degraded}) qualityDistribution(
  Iterable<HistoryWorkout> workouts,
  ExerciseId exercise,
) {
  var good = 0;
  var warning = 0;
  var degraded = 0;
  for (final set in historyForExercise(workouts, exercise)) {
    good += set.goodReps;
    warning += set.warningReps;
    degraded += set.degradedReps;
  }
  return (good: good, warning: warning, degraded: degraded);
}

WeeklyExerciseSummary weeklySummary(
  Iterable<HistoryWorkout> workouts,
  ExerciseId exercise, {
  required DateTime now,
}) {
  final localNow = now.toLocal();
  final start = DateTime(
    localNow.year,
    localNow.month,
    localNow.day,
  ).subtract(const Duration(days: 6));
  final sets = historyForExercise(workouts, exercise)
      .where((set) => !set.completedAt.toLocal().isBefore(start))
      .toList(growable: false);
  final scores = sets
      .map((set) => set.formScorePercent)
      .whereType<double>()
      .toList(growable: false);
  return WeeklyExerciseSummary(
    sets: sets.length,
    reps: sets.fold(0, (sum, set) => sum + set.totalReps),
    averageFormScore: scores.isEmpty
        ? null
        : scores.reduce((a, b) => a + b) / scores.length,
  );
}
