import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/analytics.dart';
import 'package:right_posture/domain/analytics_insights.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/history.dart';
import 'package:right_posture/domain/models.dart';

void main() {
  test('progress uses same exercise, tolerance, and metric direction', () {
    final workouts = [
      workout(day: 1, form: 70, symmetry: 0.20, consistency: 80),
      workout(
        day: 2,
        exercise: ExerciseId.bicepCurl,
        form: 100,
        symmetry: 0,
        consistency: 100,
      ),
      workout(day: 3, form: 71, symmetry: 0.10, consistency: 75),
    ];

    final insights = progressInsights(workouts, ExerciseId.squat);
    final form = insights.singleWhere(
      (item) => item.metric == AnalyticsMetric.formScore,
    );
    final symmetry = insights.singleWhere(
      (item) => item.metric == AnalyticsMetric.symmetry,
    );
    final consistency = insights.singleWhere(
      (item) => item.metric == AnalyticsMetric.consistency,
    );

    expect(form.direction, InsightDirection.unchanged);
    expect(symmetry.direction, InsightDirection.improved);
    expect(consistency.direction, InsightDirection.declined);
    expect(form.evidence.map((item) => item.timestamp.day), [1, 3]);
  });

  test('one session cannot produce a progress claim', () {
    expect(progressInsights([workout(day: 1)], ExerciseId.squat), isEmpty);
  });

  test('best results expose ties and personal records cite dates', () {
    final workouts = [
      workout(day: 1, form: 90, consistency: 80, degradation: 5),
      workout(day: 2, form: 90, consistency: 80, degradation: null),
    ];

    expect(bestSet(workouts, ExerciseId.squat)!.tied, isTrue);
    expect(bestSession(workouts, ExerciseId.squat)!.tied, isTrue);
    final records = personalRecords(workouts, ExerciseId.squat);
    expect(
      records
          .singleWhere(
            (record) => record.label == 'Longest set before degradation',
          )
          .value,
      10,
    );
    expect(records.every((record) => record.timestamp.year == 2026), isTrue);
  });

  test('feedback improvement requires repeated issue and later comparison', () {
    final issue = const HistoryIssue(
      metric: MovementMetric.torsoLean,
      direction: IssueDirection.increased,
      severity: 0.5,
    );
    final insights = feedbackInsights([
      workout(
        day: 1,
        issues: [issue, issue],
        feedback: 'Keep your torso steady',
      ),
      workout(day: 2),
    ], ExerciseId.squat);

    expect(insights, hasLength(1));
    expect(insights.single.direction, InsightDirection.improved);
    expect(insights.single.previousRate, 0.2);
    expect(insights.single.currentRate, 0);
    expect(insights.single.instruction, 'Keep your torso steady');
  });

  test(
    'weekly ranking handles strongest, ties, and insufficient exercises',
    () {
      final ranked = weeklyExerciseRanking([
        workout(day: 28, form: 90, consistency: 90),
        workout(
          day: 28,
          exercise: ExerciseId.bicepCurl,
          form: 60,
          consistency: 60,
        ),
      ], now: DateTime(2026, 8, 29));
      expect(ranked.strongest, ExerciseId.squat);
      expect(ranked.weakest, ExerciseId.bicepCurl);

      final tied = weeklyExerciseRanking([
        workout(day: 28, form: 80, consistency: 80),
        workout(
          day: 28,
          exercise: ExerciseId.bicepCurl,
          form: 80,
          consistency: 80,
        ),
      ], now: DateTime(2026, 8, 29));
      expect(tied.tied, isTrue);
      expect(tied.strongest, isNull);

      final insufficient = weeklyExerciseRanking([
        workout(day: 28),
      ], now: DateTime(2026, 8, 29));
      expect(insufficient.strongest, isNull);
    },
  );

  test('latest activity streak counts consecutive unique local days', () {
    expect(
      latestActivityStreak([
        workout(day: 29),
        workout(day: 28),
        workout(day: 28),
        workout(day: 27),
        workout(day: 25),
      ]),
      3,
    );
  });
}

HistoryWorkout workout({
  required int day,
  ExerciseId exercise = ExerciseId.squat,
  double? form = 80,
  double? symmetry = 0.1,
  double? consistency = 80,
  int? degradation = 6,
  List<HistoryIssue> issues = const [],
  String? feedback,
}) {
  final timestamp = DateTime(2026, 8, day, 12);
  return HistoryWorkout(
    completedAt: timestamp,
    sets: [
      HistorySet(
        exercise: exercise,
        completedAt: timestamp,
        totalReps: 10,
        goodReps: 6,
        warningReps: 3,
        degradedReps: 1,
        calibrationReps: 3,
        formScorePercent: form,
        componentScores: const [
          ComponentScore(
            id: 'range',
            label: 'Range consistency',
            percent: 75,
            evaluatedRepCount: 7,
          ),
          ComponentScore(
            id: 'tempo',
            label: 'Tempo consistency',
            percent: 85,
            evaluatedRepCount: 7,
          ),
        ],
        averageRange: 90,
        averageTempoSeconds: 2,
        averageSymmetrySeconds: symmetry,
        consistencyScorePercent: consistency,
        degradationStartRep: degradation,
        issues: issues,
        feedback: feedback == null ? const [] : [feedback],
        repOutcomes: feedback == null
            ? const []
            : [
                HistoryRepOutcome(
                  number: 4,
                  status: RepStatus.warning,
                  issues: issues,
                  feedback: feedback,
                ),
              ],
      ),
    ],
  );
}
