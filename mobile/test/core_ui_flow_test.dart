import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/models.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/squat_rep_detector.dart';
import 'package:right_posture/pose_camera_page.dart';
import 'package:right_posture/pose_pipeline.dart';
import 'package:right_posture/session_controller.dart';
import 'package:right_posture/settings_controller.dart';
import 'package:right_posture/ui/app_theme.dart';
import 'package:right_posture/ui/exercise_select_page.dart';
import 'package:right_posture/ui/session_summary_page.dart';
import 'package:right_posture/ui/settings_page.dart';

void main() {
  test('failed pipeline hides live HUD so recovery actions stay reachable', () {
    expect(shouldShowLiveSessionHud(PosePipelineStatus.failed), isFalse);
    expect(shouldShowLiveSessionHud(PosePipelineStatus.noPerson), isTrue);
  });

  testWidgets('squat card starts a tracking session', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
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
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.preparing,
    );
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
    expect(find.text('Rep 4 · degraded'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: SessionSummaryView(
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

    await tester.fling(find.byType(ListView), const Offset(0, -1200), 2000);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('select_squat')), findsOneWidget);
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
