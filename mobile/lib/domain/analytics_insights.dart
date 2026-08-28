import 'analytics.dart';
import 'exercise.dart';
import 'history.dart';

enum InsightDirection { improved, declined, unchanged }

class InsightEvidence {
  const InsightEvidence({
    required this.timestamp,
    required this.metric,
    required this.value,
  });

  final DateTime timestamp;
  final AnalyticsMetric metric;
  final double value;
}

class MetricInsight {
  const MetricInsight({
    required this.metric,
    required this.direction,
    required this.previousValue,
    required this.currentValue,
    required this.evidence,
  });

  final AnalyticsMetric metric;
  final InsightDirection direction;
  final double previousValue;
  final double currentValue;
  final List<InsightEvidence> evidence;
}

class RankedSet {
  const RankedSet({required this.set, required this.tied});

  final HistorySet set;
  final bool tied;
}

class RankedSession {
  const RankedSession({
    required this.workout,
    required this.formScore,
    required this.consistency,
    required this.tied,
  });

  final HistoryWorkout workout;
  final double formScore;
  final double? consistency;
  final bool tied;
}

class PersonalRecord {
  const PersonalRecord({
    required this.label,
    required this.value,
    required this.unit,
    required this.timestamp,
  });

  final String label;
  final double value;
  final String unit;
  final DateTime timestamp;
}

class FeedbackInsight {
  const FeedbackInsight({
    required this.metric,
    required this.instruction,
    required this.direction,
    required this.previousRate,
    required this.currentRate,
    required this.previousTimestamp,
    required this.currentTimestamp,
  });

  final MovementMetric metric;
  final String? instruction;
  final InsightDirection direction;
  final double previousRate;
  final double currentRate;
  final DateTime previousTimestamp;
  final DateTime currentTimestamp;
}

class WeeklyExerciseRanking {
  const WeeklyExerciseRanking({
    required this.strongest,
    required this.weakest,
    required this.scores,
    required this.tied,
  });

  final ExerciseId? strongest;
  final ExerciseId? weakest;
  final Map<ExerciseId, double> scores;
  final bool tied;
}

const _benefitMetrics = [
  AnalyticsMetric.formScore,
  AnalyticsMetric.degradationPoint,
  AnalyticsMetric.symmetry,
  AnalyticsMetric.consistency,
];

List<MetricInsight> progressInsights(
  Iterable<HistoryWorkout> workouts,
  ExerciseId exercise,
) {
  final result = <MetricInsight>[];
  for (final metric in _benefitMetrics) {
    final points = metricSeries(
      workouts,
      exercise,
      metric,
    ).where((point) => point.value != null).toList(growable: false);
    if (points.length < 2) continue;
    final previous = points[points.length - 2];
    final current = points.last;
    final delta = current.value! - previous.value!;
    final beneficialDelta = metric == AnalyticsMetric.symmetry ? -delta : delta;
    final tolerance = switch (metric) {
      AnalyticsMetric.formScore || AnalyticsMetric.consistency => 2.0,
      AnalyticsMetric.degradationPoint => 1.0,
      AnalyticsMetric.symmetry => 0.05,
      _ => double.infinity,
    };
    final direction = beneficialDelta.abs() < tolerance
        ? InsightDirection.unchanged
        : beneficialDelta > 0
        ? InsightDirection.improved
        : InsightDirection.declined;
    result.add(
      MetricInsight(
        metric: metric,
        direction: direction,
        previousValue: previous.value!,
        currentValue: current.value!,
        evidence: [
          InsightEvidence(
            timestamp: previous.timestamp,
            metric: metric,
            value: previous.value!,
          ),
          InsightEvidence(
            timestamp: current.timestamp,
            metric: metric,
            value: current.value!,
          ),
        ],
      ),
    );
  }
  return result;
}

RankedSet? bestSet(Iterable<HistoryWorkout> workouts, ExerciseId exercise) {
  final candidates = historyForExercise(
    workouts,
    exercise,
  ).where((set) => set.formScorePercent != null).toList(growable: false);
  if (candidates.isEmpty) return null;
  final sorted = [...candidates]..sort(_compareSets);
  return RankedSet(
    set: sorted.first,
    tied: sorted.length > 1 && _compareSets(sorted[0], sorted[1]) == 0,
  );
}

int _compareSets(HistorySet a, HistorySet b) {
  final form = b.formScorePercent!.compareTo(a.formScorePercent!);
  if (form != 0) return form;
  return (b.consistencyScorePercent ?? -1).compareTo(
    a.consistencyScorePercent ?? -1,
  );
}

RankedSession? bestSession(
  Iterable<HistoryWorkout> workouts,
  ExerciseId exercise,
) {
  final candidates = <RankedSession>[];
  for (final workout in workouts) {
    final sets = workout.sets
        .where((set) => set.exercise == exercise)
        .toList(growable: false);
    final forms = sets
        .map((set) => set.formScorePercent)
        .whereType<double>()
        .toList(growable: false);
    if (forms.isEmpty) continue;
    final consistencies = sets
        .map((set) => set.consistencyScorePercent)
        .whereType<double>()
        .toList(growable: false);
    candidates.add(
      RankedSession(
        workout: workout,
        formScore: _average(forms),
        consistency: consistencies.isEmpty ? null : _average(consistencies),
        tied: false,
      ),
    );
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) {
    final form = b.formScore.compareTo(a.formScore);
    if (form != 0) return form;
    return (b.consistency ?? -1).compareTo(a.consistency ?? -1);
  });
  final winner = candidates.first;
  final tied =
      candidates.length > 1 &&
      winner.formScore == candidates[1].formScore &&
      winner.consistency == candidates[1].consistency;
  return RankedSession(
    workout: winner.workout,
    formScore: winner.formScore,
    consistency: winner.consistency,
    tied: tied,
  );
}

List<PersonalRecord> personalRecords(
  Iterable<HistoryWorkout> workouts,
  ExerciseId exercise,
) {
  final sets = historyForExercise(workouts, exercise);
  final result = <PersonalRecord>[];
  _addRecord(
    result,
    sets,
    'Highest Form Score',
    'percent',
    (set) => set.formScorePercent,
  );
  _addRecord(
    result,
    sets,
    'Longest set before degradation',
    'reps',
    (set) => set.degradationStartRep == null
        ? set.totalReps.toDouble()
        : (set.degradationStartRep! - 1).clamp(0, set.totalReps).toDouble(),
  );
  _addRecord(
    result,
    sets,
    'Best consistency',
    'percent',
    (set) => set.consistencyScorePercent,
  );
  for (final id in const ['range', 'tempo']) {
    HistorySet? winner;
    double? value;
    for (final set in sets) {
      final score = set.componentScores
          .where((component) => component.id == id)
          .map((component) => component.percent)
          .whereType<double>()
          .firstOrNull;
      if (score != null && (value == null || score > value)) {
        winner = set;
        value = score;
      }
    }
    if (winner != null && value != null) {
      result.add(
        PersonalRecord(
          label: id == 'range'
              ? 'Best ROM consistency'
              : 'Most consistent tempo',
          value: value,
          unit: 'percent',
          timestamp: winner.completedAt,
        ),
      );
    }
  }
  return result;
}

void _addRecord(
  List<PersonalRecord> result,
  List<HistorySet> sets,
  String label,
  String unit,
  double? Function(HistorySet) valueFor,
) {
  HistorySet? winner;
  double? value;
  for (final set in sets) {
    final candidate = valueFor(set);
    if (candidate != null && (value == null || candidate > value)) {
      winner = set;
      value = candidate;
    }
  }
  if (winner != null && value != null) {
    result.add(
      PersonalRecord(
        label: label,
        value: value,
        unit: unit,
        timestamp: winner.completedAt,
      ),
    );
  }
}

List<FeedbackInsight> feedbackInsights(
  Iterable<HistoryWorkout> workouts,
  ExerciseId exercise,
) {
  final sets = historyForExercise(workouts, exercise)
    ..sort((a, b) => a.completedAt.compareTo(b.completedAt));
  final totals = <MovementMetric, int>{};
  for (final issue in sets.expand((set) => set.issues)) {
    totals[issue.metric] = (totals[issue.metric] ?? 0) + 1;
  }
  final result = <FeedbackInsight>[];
  for (final entry in totals.entries.where((entry) => entry.value >= 2)) {
    final firstIndex = sets.indexWhere(
      (set) => set.issues.any((issue) => issue.metric == entry.key),
    );
    if (firstIndex < 0 || firstIndex == sets.length - 1) continue;
    final first = sets[firstIndex];
    final latest = sets.last;
    final previousRate = _issueRate(first, entry.key);
    final currentRate = _issueRate(latest, entry.key);
    final delta = previousRate - currentRate;
    final direction = delta.abs() < 0.05
        ? InsightDirection.unchanged
        : delta > 0
        ? InsightDirection.improved
        : InsightDirection.declined;
    result.add(
      FeedbackInsight(
        metric: entry.key,
        instruction: _feedbackForMetric(first, entry.key),
        direction: direction,
        previousRate: previousRate,
        currentRate: currentRate,
        previousTimestamp: first.completedAt,
        currentTimestamp: latest.completedAt,
      ),
    );
  }
  return result;
}

String? _feedbackForMetric(HistorySet set, MovementMetric metric) {
  for (final rep in set.repOutcomes) {
    if (rep.feedback != null &&
        rep.issues.any((issue) => issue.metric == metric)) {
      return rep.feedback;
    }
  }
  return null;
}

double _issueRate(HistorySet set, MovementMetric metric) {
  final count = set.issues.where((issue) => issue.metric == metric).length;
  final evaluated = set.goodReps + set.warningReps + set.degradedReps;
  return evaluated == 0 ? 0 : count / evaluated;
}

WeeklyExerciseRanking weeklyExerciseRanking(
  Iterable<HistoryWorkout> workouts, {
  required DateTime now,
}) {
  final start = DateTime(
    now.toLocal().year,
    now.toLocal().month,
    now.toLocal().day,
  ).subtract(const Duration(days: 6));
  final scores = <ExerciseId, double>{};
  for (final exercise in ExerciseId.values) {
    final values = historyForExercise(workouts, exercise)
        .where((set) => !set.completedAt.toLocal().isBefore(start))
        .expand((set) => [set.formScorePercent, set.consistencyScorePercent])
        .whereType<double>()
        .toList(growable: false);
    if (values.isNotEmpty) scores[exercise] = _average(values);
  }
  if (scores.length < 2) {
    return WeeklyExerciseRanking(
      strongest: null,
      weakest: null,
      scores: scores,
      tied: false,
    );
  }
  final ordered = scores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final tied = (ordered.first.value - ordered.last.value).abs() < 0.01;
  return WeeklyExerciseRanking(
    strongest: tied ? null : ordered.first.key,
    weakest: tied ? null : ordered.last.key,
    scores: Map.unmodifiable(scores),
    tied: tied,
  );
}

int latestActivityStreak(Iterable<HistoryWorkout> workouts) {
  final days =
      workouts
          .map((workout) {
            final date = workout.completedAt.toLocal();
            return DateTime(date.year, date.month, date.day);
          })
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a));
  if (days.isEmpty) return 0;
  var streak = 1;
  for (var index = 1; index < days.length; index++) {
    if (days[index - 1].difference(days[index]).inDays != 1) break;
    streak++;
  }
  return streak;
}

double _average(List<double> values) =>
    values.reduce((a, b) => a + b) / values.length;
