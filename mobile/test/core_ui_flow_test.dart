import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/models.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/squat_rep_detector.dart';
import 'package:right_posture/domain/workout.dart';
import 'package:right_posture/history_storage.dart';
import 'package:right_posture/pose_camera_page.dart';
import 'package:right_posture/pose_pipeline.dart';
import 'package:right_posture/session_controller.dart';
import 'package:right_posture/settings_controller.dart';
import 'package:right_posture/ui/app_theme.dart';
import 'package:right_posture/ui/exercise_select_page.dart';
import 'package:right_posture/ui/guided_demo_page.dart';
import 'package:right_posture/ui/session_summary_page.dart';
import 'package:right_posture/ui/settings_page.dart';
import 'package:right_posture/ui/workout_summary_page.dart';

void main() {
  test('failed pipeline hides live HUD so recovery actions stay reachable', () {
    expect(shouldShowLiveSessionHud(PosePipelineStatus.failed), isFalse);
    expect(shouldShowLiveSessionHud(PosePipelineStatus.noPerson), isTrue);
  });

  testWidgets('squat card starts a tracking session', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyStorageProvider.overrideWithValue(
            HistoryStorage(VisitedHistoryBackend()),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ExerciseSelectPage(),
        ),
      ),
    );

    final context = tester.element(find.byType(ExerciseSelectPage));
    final container = ProviderScope.containerOf(context);
    expect(container.read(sessionControllerProvider).phase, SessionPhase.idle);

    await tester.tap(find.byKey(const Key('select_squat')));
    await tester.pump();
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.preparing,
    );
  });

  testWidgets('first exercise visit opens guided demo without starting set', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyStorageProvider.overrideWithValue(
            HistoryStorage(EmptyHistoryBackend()),
          ),
          initialCoachingPreferencesProvider.overrideWithValue(
            const CoachingPreferences(ttsEnabled: false),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ExerciseSelectPage(),
        ),
      ),
    );
    final context = tester.element(find.byType(ExerciseSelectPage));
    final container = ProviderScope.containerOf(context);

    await tester.tap(find.byKey(const Key('select_squat')));
    await tester.pump();
    await tester.pump();

    expect(find.byType(GuidedDemoPage), findsOneWidget);
    expect(container.read(sessionControllerProvider).phase, SessionPhase.idle);
    await tester.tap(find.byKey(const Key('close_guided_demo')));
    await tester.pumpAndSettle();
    expect(container.read(sessionControllerProvider).phase, SessionPhase.idle);
  });

  testWidgets('debug curl card starts bicep curl preparation', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyStorageProvider.overrideWithValue(
            HistoryStorage(VisitedHistoryBackend()),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ExerciseSelectPage(),
        ),
      ),
    );

    final context = tester.element(find.byType(ExerciseSelectPage));
    final container = ProviderScope.containerOf(context);
    await tester.tap(find.byKey(const Key('select_bicep_curl')));
    await tester.pump();

    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.preparing);
    expect(state.selectedExercise, ExerciseId.bicepCurl);
  });

  testWidgets('debug lateral raise card starts correct preparation', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          historyStorageProvider.overrideWithValue(
            HistoryStorage(VisitedHistoryBackend()),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const ExerciseSelectPage(),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('select_lateral_raise')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(ExerciseSelectPage));
    final container = ProviderScope.containerOf(context);
    await tester.tap(find.byKey(const Key('select_lateral_raise')));
    await tester.pump();

    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.preparing);
    expect(state.selectedExercise, ExerciseId.lateralRaise);
  });

  testWidgets('squat preparation fits compact screen at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: PreparationHud(
                state: SessionState(
                  phase: SessionPhase.preparing,
                  selectedExercise: ExerciseId.squat,
                  placementStable: true,
                  placementGuidance: 'Position ready',
                ),
                exerciseName: 'Squat',
                instruction: squatExerciseProfile.setupInstruction,
                onStart: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('start_set')), findsOneWidget);
    expect(find.text('Position ready'), findsOneWidget);
  });

  testWidgets('curl preparation contains no squat copy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: PreparationHud(
            state: SessionState(
              phase: SessionPhase.preparing,
              selectedExercise: ExerciseId.bicepCurl,
            ),
            exerciseName: 'Bicep Curl',
            instruction: bicepCurlExerciseProfile.setupInstruction,
            onStart: () {},
          ),
        ),
      ),
    );

    expect(find.text('Set up your Bicep Curl'), findsOneWidget);
    expect(find.textContaining('squat', findRichText: true), findsNothing);
  });

  testWidgets('lateral raise preparation contains correct copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: PreparationHud(
            state: SessionState(
              phase: SessionPhase.preparing,
              selectedExercise: ExerciseId.lateralRaise,
            ),
            exerciseName: 'Lateral Raise',
            instruction: lateralRaiseExerciseProfile.setupInstruction,
            onStart: () {},
          ),
        ),
      ),
    );

    expect(find.text('Set up your Lateral Raise'), findsOneWidget);
    expect(find.textContaining('squat', findRichText: true), findsNothing);
    expect(find.textContaining('curl', findRichText: true), findsNothing);
  });

  testWidgets('shoulder press preparation contains correct copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: PreparationHud(
            state: SessionState(
              phase: SessionPhase.preparing,
              selectedExercise: ExerciseId.shoulderPress,
            ),
            exerciseName: 'Shoulder Press',
            instruction: shoulderPressExerciseProfile.setupInstruction,
            onStart: () {},
          ),
        ),
      ),
    );

    expect(find.text('Set up your Shoulder Press'), findsOneWidget);
    expect(find.textContaining('squat', findRichText: true), findsNothing);
    expect(find.textContaining('curl', findRichText: true), findsNothing);
    expect(find.textContaining('lateral', findRichText: true), findsNothing);
  });

  testWidgets('live HUD shows calibration and ends the set', (tester) async {
    var ended = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: LiveSessionHud(
            state: SessionState(
              phase: SessionPhase.tracking,
              selectedExercise: ExerciseId.squat,
              reps: [calibrationRep(1), calibrationRep(2)],
            ),
            onEnd: () => ended = true,
          ),
        ),
      ),
    );

    expect(find.text('Calibrating 2 of 3'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(find.byKey(const Key('end_session')));
    expect(ended, isTrue);
  });

  testWidgets('live HUD shows compact coaching text', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: LiveSessionHud(
            state: SessionState(
              phase: SessionPhase.tracking,
              selectedExercise: ExerciseId.squat,
              coaching: SquatCoaching.goLower,
            ),
            onEnd: () {},
          ),
        ),
      ),
    );

    expect(find.text('Go lower'), findsOneWidget);
    final text = tester.widget<Text>(find.text('Go lower'));
    expect(text.maxLines, 2);
  });

  testWidgets('settings independently toggle voice and haptics', (
    tester,
  ) async {
    final storage = WidgetSettingsStorage();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsStorageProvider.overrideWithValue(storage)],
        child: MaterialApp(theme: buildAppTheme(), home: const SettingsPage()),
      ),
    );

    expect(find.text('Voice coaching'), findsOneWidget);
    expect(find.text('Haptic coaching'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tts_setting')));
    await tester.tap(find.byKey(const Key('haptics_setting')));
    await tester.pump();
    expect(storage.tts, isFalse);
    expect(storage.haptics, isFalse);
  });

  testWidgets('settings fit compact screen at 200% text scale', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsStorageProvider.overrideWithValue(WidgetSettingsStorage()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: const SettingsPage(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Voice coaching'), findsOneWidget);
    expect(find.text('Haptic coaching'), findsOneWidget);
  });

  testWidgets('live HUD replaces stale verdict when tracking is lost', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: LiveSessionHud(
            state: SessionState(
              phase: SessionPhase.tracking,
              selectedExercise: ExerciseId.squat,
              latestFeedback: Rep(
                number: 4,
                angles: const {'knee': 100},
                status: RepStatus.good,
              ),
            ),
            pipelineStatus: PosePipelineStatus.noPerson,
            onEnd: () {},
          ),
        ),
      ),
    );

    expect(find.text('Tracking paused. Step into frame'), findsOneWidget);
    expect(find.text('Good rep'), findsNothing);
  });

  testWidgets('summary handles insufficient and degraded results', (
    tester,
  ) async {
    final degradedRep = Rep(
      number: 4,
      angles: const {'knee': 60},
      status: RepStatus.degraded,
      issues: const [
        RepIssue(
          exercise: ExerciseId.squat,
          metric: MovementMetric.kneeAngle,
          direction: IssueDirection.aboveRange,
          measuredValue: 60,
          normalizedSeverity: 1,
        ),
      ],
    );
    final state = SessionState(
      phase: SessionPhase.complete,
      selectedExercise: ExerciseId.squat,
      reps: [
        calibrationRep(1),
        calibrationRep(2),
        calibrationRep(3),
        degradedRep,
      ],
      summary: SessionSummary(
        totalReps: 4,
        formScorePercent: 0,
        degradationStartRep: 4,
        primaryResponsibleJoint: 'Knee range',
        repChecklist: [degradedRep],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: SessionSummaryView(state: state, onRestart: () {}),
      ),
    );
    expect(find.text('0%'), findsOneWidget);
    expect(
      find.textContaining('Form degradation detected from rep 4'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Rep 4 · degraded'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
    await tester.pumpAndSettle();
    expect(find.text('Rep 4 · degraded'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: SessionSummaryView(
          key: const Key('empty_summary'),
          state: SessionState(
            phase: SessionPhase.complete,
            selectedExercise: ExerciseId.squat,
            summary: SessionSummary(
              totalReps: 0,
              formScorePercent: null,
              degradationStartRep: null,
              primaryResponsibleJoint: null,
              repChecklist: const [],
            ),
          ),
          onRestart: () {},
        ),
      ),
    );
    expect(find.text('Not enough data'), findsOneWidget);
  });

  testWidgets('rep timeline opens accessible movement details', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final rep = Rep(
      number: 4,
      angles: const {'left': 90},
      status: RepStatus.warning,
      metrics: RepMetrics(
        totalDuration: const Duration(seconds: 2),
        outwardDuration: const Duration(seconds: 1),
        returnDuration: const Duration(seconds: 1),
        rangeOfMotion: const {MovementMetric.leftArmElevation: 80},
        completionConfidence: 0.9,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: SessionSummaryView(
            state: SessionState(
              phase: SessionPhase.complete,
              selectedExercise: ExerciseId.lateralRaise,
              reps: [rep],
              summary: SessionSummary(
                totalReps: 1,
                formScorePercent: null,
                degradationStartRep: null,
                primaryResponsibleJoint: null,
                repChecklist: [rep],
                warningRepCount: 1,
              ),
            ),
            onRestart: () {},
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.byKey(const Key('rep_timeline_4')),
      50,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rep_timeline_4')));
    await tester.pumpAndSettle();

    expect(find.text('Tempo: 2.0 s'), findsOneWidget);
    expect(find.text('Arm elevation: 80.0°'), findsOneWidget);
    expect(find.text('Confidence: 90%'), findsOneWidget);
  });

  testWidgets('workout summary compares only same-exercise sets', (
    tester,
  ) async {
    CompletedSet set(int number, ExerciseId exercise, double score) =>
        CompletedSet(
          setNumber: number,
          exercise: exercise,
          completedAt: DateTime(2026),
          reps: const [],
          summary: SessionSummary(
            totalReps: 5,
            formScorePercent: score,
            degradationStartRep: null,
            primaryResponsibleJoint: null,
            repChecklist: const [],
          ),
        );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: WorkoutSummaryView(
          workout: WorkoutState(
            completedSets: [
              set(1, ExerciseId.squat, 60),
              set(2, ExerciseId.bicepCurl, 95),
              set(3, ExerciseId.squat, 80),
            ],
            isFinished: true,
          ),
          onNewWorkout: () {},
        ),
      ),
    );

    expect(find.text('3 sets · 15 reps'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Form Score improved by 20 points.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Bicep Curl'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Bicep Curl'), findsOneWidget);
    expect(find.text('Form Score improved by 35 points.'), findsNothing);
  });

  testWidgets('exercise selection fits 320px width at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildAppTheme(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.linear(2),
            ),
            child: const ExerciseSelectPage(),
          ),
        ),
      ),
    );

    expect(find.text('Choose your exercise'), findsOneWidget);
    await tester.fling(find.byType(ListView), const Offset(0, -1200), 2000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('select_lateral_raise')), findsOneWidget);
  });

  testWidgets('live HUD fits compact screen at 200% text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: LiveSessionHud(
                state: SessionState(
                  phase: SessionPhase.tracking,
                  selectedExercise: ExerciseId.squat,
                  coaching: SquatCoaching.goLower,
                ),
                pipelineStatus: PosePipelineStatus.ready,
                onEnd: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('end_session')), findsOneWidget);
    expect(find.text('Go lower'), findsOneWidget);
  });
}

class VisitedHistoryBackend implements HistoryBackend {
  static const _value =
      '{"version":1,"workouts":[],"demoVisits":'
      '["squat","bicepCurl","lateralRaise","shoulderPress"]}';

  @override
  Future<String?> getString(String key) async => _value;

  @override
  Future<void> setString(String key, String value) async {}
}

class EmptyHistoryBackend implements HistoryBackend {
  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<void> setString(String key, String value) async {}
}

Rep calibrationRep(int number) => Rep(
  number: number,
  angles: const {'knee': 100},
  status: RepStatus.calibrating,
);

class WidgetSettingsStorage implements SettingsStorage {
  bool? tts;
  bool? haptics;

  @override
  Future<CoachingPreferences> load() async => const CoachingPreferences();

  @override
  Future<void> saveHaptics(bool value) async => haptics = value;

  @override
  Future<void> saveTts(bool value) async => tts = value;
}
