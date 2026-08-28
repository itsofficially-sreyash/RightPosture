import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/analytics.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/history.dart';
import 'package:right_posture/domain/models.dart';
import 'package:right_posture/domain/workout.dart';
import 'package:right_posture/ui/analytics_page.dart';

void main() {
  test('metric series separates exercises and preserves missing gaps', () {
    final workouts = [
      history(day: 1, exercise: ExerciseId.squat, formScore: 70),
      history(day: 2, exercise: ExerciseId.bicepCurl, formScore: 99),
      history(day: 3, exercise: ExerciseId.squat, formScore: null),
      history(day: 4, exercise: ExerciseId.squat, formScore: 80),
    ];

    final points = metricSeries(
      workouts,
      ExerciseId.squat,
      AnalyticsMetric.formScore,
    );

    expect(points.map((point) => point.value), [70, null, 80]);
    expect(splitTrendSegments(points), hasLength(2));
  });

  test('weekly and quality summaries use selected exercise only', () {
    final workouts = [
      history(day: 27, exercise: ExerciseId.squat, formScore: 60),
      history(day: 28, exercise: ExerciseId.squat, formScore: 80),
      history(day: 28, exercise: ExerciseId.bicepCurl, formScore: 100),
    ];

    final week = weeklySummary(
      workouts,
      ExerciseId.squat,
      now: DateTime(2026, 8, 29),
    );
    final quality = qualityDistribution(workouts, ExerciseId.squat);

    expect(week.sets, 2);
    expect(week.reps, 8);
    expect(week.averageFormScore, 70);
    expect(quality, (good: 4, warning: 2, degraded: 2));
  });

  testWidgets('empty history has an honest empty state', (tester) async {
    await tester.pumpWidget(appWithHistory(const []));
    await tester.pumpAndSettle();

    expect(
      find.text('Complete a workout to create movement-quality analytics.'),
      findsOneWidget,
    );
    expect(find.byType(LineChart), findsNothing);
  });

  testWidgets('progress insight exposes both supporting sessions', (
    tester,
  ) async {
    await tester.pumpWidget(
      appWithHistory([
        history(day: 1, exercise: ExerciseId.squat, formScore: 70),
        history(day: 3, exercise: ExerciseId.squat, formScore: 80),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Form Score: improved'), findsOneWidget);
    expect(find.text('Earlier · 2026-08-01'), findsWidgets);
    expect(find.text('Later · 2026-08-03'), findsWidgets);
  });

  testWidgets('one point does not pretend to be a trend at 200% text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: appWithHistory([
          history(day: 29, exercise: ExerciseId.squat, formScore: 75),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    for (var index = 0; index < 8; index++) {
      if (find
          .textContaining('Not enough data for a trend')
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -700));
      await tester.pump();
    }
    expect(find.textContaining('Not enough data for a trend'), findsWidgets);
    expect(find.byType(LineChart), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

Widget appWithHistory(List<HistoryWorkout> workouts) {
  return ProviderScope(
    overrides: [historyProvider.overrideWith((ref) async => workouts)],
    child: const MaterialApp(home: AnalyticsPage()),
  );
}

HistoryWorkout history({
  required int day,
  required ExerciseId exercise,
  required double? formScore,
}) {
  final rep = Rep(
    number: 4,
    angles: const {},
    status: RepStatus.warning,
    issues: const [],
    metrics: RepMetrics(
      totalDuration: Duration(seconds: 2),
      outwardDuration: Duration(seconds: 1),
      returnDuration: Duration(seconds: 1),
      rangeOfMotion: {MovementMetric.leftKneeAngle: 90},
      bilateralTimingDifference: Duration(milliseconds: 100),
      completionConfidence: 0.9,
    ),
  );
  final completedAt = DateTime(2026, 8, day, 12);
  final summary = SessionSummary(
    totalReps: 4,
    formScorePercent: formScore,
    degradationStartRep: null,
    primaryResponsibleJoint: null,
    repChecklist: [rep],
    componentScores: const [],
    averageTempoSeconds: 2,
    averageSymmetrySeconds: 0.1,
    consistencyScorePercent: 90,
    goodRepCount: 2,
    warningRepCount: 1,
    degradedRepCount: 1,
    calibrationRepCount: 3,
  );
  return HistoryWorkout.fromCompletedSets([
    CompletedSet(
      setNumber: 1,
      exercise: exercise,
      completedAt: completedAt,
      reps: [rep],
      summary: summary,
    ),
  ]);
}
