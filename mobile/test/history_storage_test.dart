import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/history.dart';
import 'package:right_posture/domain/models.dart';
import 'package:right_posture/domain/workout.dart';
import 'package:right_posture/history_storage.dart';

void main() {
  test('versioned history round-trips summary evidence only', () async {
    final backend = MemoryHistoryBackend();
    final storage = HistoryStorage(backend);

    await storage.saveWorkout(sampleWorkout(), note: 'Used 5 kg dumbbells');
    final loaded = await storage.load();

    expect(loaded, hasLength(1));
    expect(loaded.single.note, 'Used 5 kg dumbbells');
    expect(loaded.single.sets.single.exercise, ExerciseId.bicepCurl);
    expect(loaded.single.sets.single.totalReps, 4);
    expect(loaded.single.sets.single.averageRange, 90);
    expect(loaded.single.sets.single.feedback, isNotEmpty);
    expect(
      loaded.single.sets.single.repOutcomes.single.status,
      RepStatus.warning,
    );
    final raw = backend.values[HistoryStorage.key]!;
    expect(raw, contains('"version":1'));
    expect(raw, isNot(contains('landmark')));
    expect(raw, isNot(contains('image')));
    expect(raw, isNot(contains('pose')));
    expect(raw, isNot(contains('angles')));
  });

  test('retention keeps newest workouts only', () async {
    final backend = MemoryHistoryBackend();
    final storage = HistoryStorage(backend, retentionLimit: 2);

    await storage.saveWorkout(sampleWorkout(day: 1));
    await storage.saveWorkout(sampleWorkout(day: 2));
    await storage.saveWorkout(sampleWorkout(day: 3));

    final loaded = await storage.load();
    expect(loaded, hasLength(2));
    expect(loaded.map((item) => item.completedAt.day), [2, 3]);
  });

  test('corrupt and unknown versions return empty history', () async {
    final backend = MemoryHistoryBackend();
    final storage = HistoryStorage(backend);

    backend.values[HistoryStorage.key] = '{bad json';
    expect(await storage.load(), isEmpty);
    backend.values[HistoryStorage.key] = '{"version":99,"workouts":[]}';
    expect(await storage.load(), isEmpty);
  });

  test('history groups by local day and filters exercise', () async {
    final first = HistoryWorkout.fromCompletedSets(
      sampleWorkout(day: 1).completedSets,
    );
    final second = HistoryWorkout.fromCompletedSets(
      sampleWorkout(day: 2, exercise: ExerciseId.squat).completedSets,
    );

    final days = groupHistoryByLocalDay([first, second]);
    expect(days, hasLength(2));
    expect(
      historyForExercise([first, second], ExerciseId.bicepCurl),
      hasLength(1),
    );
    expect(historyForExercise([first, second], ExerciseId.squat), hasLength(1));
  });

  test(
    'guided demo visits share versioned store without losing history',
    () async {
      final backend = MemoryHistoryBackend();
      final storage = HistoryStorage(backend);
      await storage.saveWorkout(sampleWorkout());

      await storage.markDemoVisited(ExerciseId.bicepCurl.name);

      expect(await storage.load(), hasLength(1));
      expect(await storage.loadDemoVisits(), {ExerciseId.bicepCurl.name});
    },
  );

  test('session note update preserves workout evidence', () async {
    final backend = MemoryHistoryBackend();
    final storage = HistoryStorage(backend);
    await storage.saveWorkout(sampleWorkout());
    final before = (await storage.load()).single;

    await storage.updateNote(before.completedAt, ' Felt strong ');
    final after = (await storage.load()).single;

    expect(after.note, 'Felt strong');
    expect(after.sets.single.toJson(), before.sets.single.toJson());
  });
}

WorkoutState sampleWorkout({
  int day = 1,
  ExerciseId exercise = ExerciseId.bicepCurl,
}) {
  final rep = Rep(
    number: 4,
    angles: const {'left': 70, 'right': 72},
    status: RepStatus.warning,
    issues: [
      RepIssue(
        exercise: exercise,
        metric: MovementMetric.leftElbowAngle,
        direction: IssueDirection.increased,
        measuredValue: 70,
        normalizedSeverity: 0.5,
      ),
    ],
    metrics: RepMetrics(
      totalDuration: const Duration(seconds: 2),
      outwardDuration: const Duration(seconds: 1),
      returnDuration: const Duration(seconds: 1),
      rangeOfMotion: const {
        MovementMetric.leftElbowAngle: 90,
        MovementMetric.rightElbowAngle: 90,
      },
      bilateralTimingDifference: const Duration(milliseconds: 100),
      completionConfidence: 0.9,
    ),
  );
  final summary = SessionSummary(
    totalReps: 4,
    formScorePercent: 50,
    degradationStartRep: null,
    primaryResponsibleJoint: null,
    repChecklist: [rep],
    componentScores: const [
      ComponentScore(
        id: 'tempo',
        label: 'Tempo consistency',
        percent: 90,
        evaluatedRepCount: 1,
      ),
    ],
    averageTempoSeconds: 2,
    averageSymmetrySeconds: 0.1,
    consistencyScorePercent: 90,
    warningRepCount: 1,
    calibrationRepCount: 3,
  );
  final completedAt = DateTime(2026, 8, day, 12);
  return WorkoutState(
    completedSets: [
      CompletedSet(
        setNumber: 1,
        exercise: exercise,
        completedAt: completedAt,
        reps: [rep],
        summary: summary,
      ),
    ],
    isFinished: true,
  );
}

class MemoryHistoryBackend implements HistoryBackend {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
