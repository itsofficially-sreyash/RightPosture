import 'exercise.dart';
import 'feedback_catalog.dart';
import 'models.dart';
import 'workout.dart';

class HistoryWorkout {
  HistoryWorkout({
    required this.completedAt,
    required List<HistorySet> sets,
    this.note,
  }) : sets = List.unmodifiable(sets);

  final DateTime completedAt;
  final List<HistorySet> sets;
  final String? note;

  factory HistoryWorkout.fromCompletedSets(
    List<CompletedSet> completedSets, {
    String? note,
  }) {
    final sets = completedSets.map(HistorySet.fromCompletedSet).toList();
    final completedAt = sets.isEmpty
        ? DateTime.now()
        : sets
              .map((set) => set.completedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b);
    return HistoryWorkout(completedAt: completedAt, sets: sets, note: note);
  }

  Map<String, Object?> toJson() => {
    'completedAt': completedAt.toIso8601String(),
    'sets': sets.map((set) => set.toJson()).toList(),
    if (note != null) 'note': note,
  };

  static HistoryWorkout? tryParse(Object? value) {
    try {
      final json = value as Map<String, Object?>;
      final sets = (json['sets'] as List<Object?>)
          .map(HistorySet.tryParse)
          .whereType<HistorySet>()
          .toList(growable: false);
      if (sets.isEmpty) return null;
      return HistoryWorkout(
        completedAt: DateTime.parse(json['completedAt'] as String),
        sets: sets,
        note: json['note'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

class HistorySet {
  HistorySet({
    required this.exercise,
    required this.completedAt,
    required this.totalReps,
    required this.goodReps,
    required this.warningReps,
    required this.degradedReps,
    required this.calibrationReps,
    required this.formScorePercent,
    required List<ComponentScore> componentScores,
    required this.averageRange,
    required this.averageTempoSeconds,
    required this.averageSymmetrySeconds,
    required this.consistencyScorePercent,
    required this.degradationStartRep,
    required List<HistoryIssue> issues,
    required List<String> feedback,
    required List<HistoryRepOutcome> repOutcomes,
  }) : componentScores = List.unmodifiable(componentScores),
       issues = List.unmodifiable(issues),
       feedback = List.unmodifiable(feedback),
       repOutcomes = List.unmodifiable(repOutcomes);

  final ExerciseId exercise;
  final DateTime completedAt;
  final int totalReps;
  final int goodReps;
  final int warningReps;
  final int degradedReps;
  final int calibrationReps;
  final double? formScorePercent;
  final List<ComponentScore> componentScores;
  final double? averageRange;
  final double? averageTempoSeconds;
  final double? averageSymmetrySeconds;
  final double? consistencyScorePercent;
  final int? degradationStartRep;
  final List<HistoryIssue> issues;
  final List<String> feedback;
  final List<HistoryRepOutcome> repOutcomes;

  factory HistorySet.fromCompletedSet(CompletedSet set) {
    final ranges = set.reps
        .map((rep) => rep.metrics?.rangeOfMotion.values)
        .whereType<Iterable<double>>()
        .where((values) => values.isNotEmpty)
        .map((values) => values.reduce((a, b) => a + b) / values.length)
        .toList(growable: false);
    final issues = set.reps
        .expand((rep) => rep.issues)
        .map(HistoryIssue.fromRepIssue)
        .toList(growable: false);
    final feedback = set.reps
        .map(feedbackForRep)
        .whereType<String>()
        .toSet()
        .toList(growable: false);
    final summary = set.summary;
    return HistorySet(
      exercise: set.exercise,
      completedAt: set.completedAt,
      totalReps: summary.totalReps,
      goodReps: summary.goodRepCount,
      warningReps: summary.warningRepCount,
      degradedReps: summary.degradedRepCount,
      calibrationReps: summary.calibrationRepCount,
      formScorePercent: summary.formScorePercent,
      componentScores: summary.componentScores,
      averageRange: ranges.isEmpty
          ? null
          : ranges.reduce((a, b) => a + b) / ranges.length,
      averageTempoSeconds: summary.averageTempoSeconds,
      averageSymmetrySeconds: summary.averageSymmetrySeconds,
      consistencyScorePercent: summary.consistencyScorePercent,
      degradationStartRep: summary.degradationStartRep,
      issues: issues,
      feedback: feedback,
      repOutcomes: set.reps.map(HistoryRepOutcome.fromRep).toList(),
    );
  }

  Map<String, Object?> toJson() => {
    'exercise': exercise.name,
    'completedAt': completedAt.toIso8601String(),
    'totalReps': totalReps,
    'outcomes': {
      'good': goodReps,
      'warning': warningReps,
      'degraded': degradedReps,
      'calibration': calibrationReps,
    },
    'formScore': formScorePercent,
    'components': componentScores
        .map(
          (score) => {
            'id': score.id,
            'label': score.label,
            'percent': score.percent,
            'count': score.evaluatedRepCount,
          },
        )
        .toList(),
    'averageRange': averageRange,
    'averageTempo': averageTempoSeconds,
    'averageSymmetry': averageSymmetrySeconds,
    'consistency': consistencyScorePercent,
    'degradationStartRep': degradationStartRep,
    'issues': issues.map((issue) => issue.toJson()).toList(),
    'feedback': feedback,
    'repOutcomes': repOutcomes.map((rep) => rep.toJson()).toList(),
  };

  static HistorySet? tryParse(Object? value) {
    try {
      final json = value as Map<String, Object?>;
      final exerciseName = json['exercise'] as String;
      final exercise = ExerciseId.values.firstWhere(
        (candidate) => candidate.name == exerciseName,
      );
      final outcomes = json['outcomes'] as Map<String, Object?>;
      final components = (json['components'] as List<Object?>)
          .map((value) {
            final item = value as Map<String, Object?>;
            return ComponentScore(
              id: item['id'] as String,
              label: item['label'] as String,
              percent: (item['percent'] as num?)?.toDouble(),
              evaluatedRepCount: item['count'] as int,
            );
          })
          .toList(growable: false);
      return HistorySet(
        exercise: exercise,
        completedAt: DateTime.parse(json['completedAt'] as String),
        totalReps: json['totalReps'] as int,
        goodReps: outcomes['good'] as int,
        warningReps: outcomes['warning'] as int,
        degradedReps: outcomes['degraded'] as int,
        calibrationReps: outcomes['calibration'] as int,
        formScorePercent: (json['formScore'] as num?)?.toDouble(),
        componentScores: components,
        averageRange: (json['averageRange'] as num?)?.toDouble(),
        averageTempoSeconds: (json['averageTempo'] as num?)?.toDouble(),
        averageSymmetrySeconds: (json['averageSymmetry'] as num?)?.toDouble(),
        consistencyScorePercent: (json['consistency'] as num?)?.toDouble(),
        degradationStartRep: json['degradationStartRep'] as int?,
        issues: (json['issues'] as List<Object?>)
            .map(HistoryIssue.tryParse)
            .whereType<HistoryIssue>()
            .toList(growable: false),
        feedback: (json['feedback'] as List<Object?>).cast<String>(),
        repOutcomes: (json['repOutcomes'] as List<Object?>? ?? const [])
            .map(HistoryRepOutcome.tryParse)
            .whereType<HistoryRepOutcome>()
            .toList(growable: false),
      );
    } catch (_) {
      return null;
    }
  }
}

class HistoryRepOutcome {
  HistoryRepOutcome({
    required this.number,
    required this.status,
    required List<HistoryIssue> issues,
    this.feedback,
  }) : issues = List.unmodifiable(issues);

  final int number;
  final RepStatus status;
  final List<HistoryIssue> issues;
  final String? feedback;

  factory HistoryRepOutcome.fromRep(Rep rep) => HistoryRepOutcome(
    number: rep.number,
    status: rep.status,
    issues: rep.issues.map(HistoryIssue.fromRepIssue).toList(),
    feedback: feedbackForRep(rep),
  );

  Map<String, Object?> toJson() => {
    'number': number,
    'status': status.name,
    'issues': issues.map((issue) => issue.toJson()).toList(),
    if (feedback != null) 'feedback': feedback,
  };

  static HistoryRepOutcome? tryParse(Object? value) {
    try {
      final json = value as Map<String, Object?>;
      return HistoryRepOutcome(
        number: json['number'] as int,
        status: RepStatus.values.firstWhere(
          (status) => status.name == json['status'],
        ),
        issues: (json['issues'] as List<Object?>)
            .map(HistoryIssue.tryParse)
            .whereType<HistoryIssue>()
            .toList(growable: false),
        feedback: json['feedback'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}

class HistoryIssue {
  const HistoryIssue({
    required this.metric,
    required this.direction,
    required this.severity,
  });

  final MovementMetric metric;
  final IssueDirection direction;
  final double severity;

  factory HistoryIssue.fromRepIssue(RepIssue issue) => HistoryIssue(
    metric: issue.metric,
    direction: issue.direction,
    severity: issue.normalizedSeverity,
  );

  Map<String, Object?> toJson() => {
    'metric': metric.name,
    'direction': direction.name,
    'severity': severity,
  };

  static HistoryIssue? tryParse(Object? value) {
    try {
      final json = value as Map<String, Object?>;
      return HistoryIssue(
        metric: MovementMetric.values.firstWhere(
          (item) => item.name == json['metric'],
        ),
        direction: IssueDirection.values.firstWhere(
          (item) => item.name == json['direction'],
        ),
        severity: (json['severity'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }
}

Map<String, List<HistoryWorkout>> groupHistoryByLocalDay(
  Iterable<HistoryWorkout> workouts,
) {
  final result = <String, List<HistoryWorkout>>{};
  for (final workout in workouts) {
    final local = workout.completedAt.toLocal();
    final key =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    result.putIfAbsent(key, () => []).add(workout);
  }
  return result;
}

List<HistorySet> historyForExercise(
  Iterable<HistoryWorkout> workouts,
  ExerciseId exercise,
) => workouts
    .expand((workout) => workout.sets)
    .where((set) => set.exercise == exercise)
    .toList(growable: false);
