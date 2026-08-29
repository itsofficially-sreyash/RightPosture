import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/feedback_catalog.dart';
import 'package:right_posture/domain/models.dart';
import 'package:right_posture/domain/rep_evaluator.dart';
import 'package:right_posture/pose_landmark_mapper.dart';
import 'package:right_posture/session_controller.dart';
import 'package:right_posture/history_storage.dart';

void main() {
  late ProviderContainer container;
  late SessionController controller;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    controller = container.read(sessionControllerProvider.notifier);
  });

  test('preparation gates countdown and tracking', () {
    controller.prepareSession();
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.preparing,
    );

    const ready = PlacementResult(PlacementStatus.ready, 'Position ready');
    controller.acceptPreparationResult(ready);
    controller.acceptPreparationResult(ready);
    expect(container.read(sessionControllerProvider).placementStable, isFalse);
    controller.acceptPoseSample(sample(170));
    expect(container.read(sessionControllerProvider).reps, isEmpty);

    controller.acceptPreparationResult(ready);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.countdown,
    );
    expect(container.read(sessionControllerProvider).countdownValue, 3);
    completeRep(controller, 100);
    expect(container.read(sessionControllerProvider).reps, isEmpty);

    controller.advanceCountdown();
    expect(container.read(sessionControllerProvider).countdownValue, 2);
    controller.advanceCountdown();
    expect(container.read(sessionControllerProvider).countdownValue, 1);
    controller.advanceCountdown();
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.tracking,
    );
  });

  test('set target survives preparation and countdown', () {
    controller.prepareSession();
    controller.setTargetRepCount(10);
    const ready = PlacementResult(PlacementStatus.ready, 'Position ready');
    for (var index = 0; index < 3; index++) {
      controller.acceptPreparationResult(ready);
    }
    expect(container.read(sessionControllerProvider).targetRepCount, 10);
    controller.advanceCountdown();
    controller.advanceCountdown();
    controller.advanceCountdown();
    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.tracking);
    expect(state.targetRepCount, 10);
  });

  test('finite target automatically completes every implemented exercise', () {
    for (final exercise in [
      ExerciseId.squat,
      ExerciseId.bicepCurl,
      ExerciseId.lateralRaise,
      ExerciseId.shoulderPress,
    ]) {
      controller.prepareSession(exercise: exercise);
      controller.setTargetRepCount(1);
      controller.startTracking();

      switch (exercise) {
        case ExerciseId.squat:
          completeRep(controller, 100);
        case ExerciseId.bicepCurl:
          repeatCurl(controller, 165, 165);
          repeatCurl(controller, 70, 75);
          repeatCurl(controller, 165, 165);
        case ExerciseId.lateralRaise:
          repeatLateralRaise(controller, 10, 10);
          repeatLateralRaise(controller, 90, 90);
          repeatLateralRaise(controller, 10, 10);
        case ExerciseId.shoulderPress:
          repeatShoulderPress(controller, 95, 95, 90);
          repeatShoulderPress(controller, 165, 165, 170);
          repeatShoulderPress(controller, 95, 95, 90);
        default:
          fail('${exercise.name} is not an implemented tracking exercise.');
      }

      final state = container.read(sessionControllerProvider);
      expect(state.phase, SessionPhase.complete, reason: exercise.name);
      expect(state.reps, hasLength(1), reason: exercise.name);
      expect(state.workout.completedSets, hasLength(1), reason: exercise.name);
      controller.reset();
    }
  });

  test('open target continues until the user explicitly ends the set', () {
    controller.startTracking();
    completeRep(controller, 100);

    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.tracking,
    );
    expect(
      container.read(sessionControllerProvider).workout.completedSets,
      isEmpty,
    );

    controller.endSession();
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.complete,
    );
    expect(
      container.read(sessionControllerProvider).workout.completedSets,
      hasLength(1),
    );
  });

  test('user can explicitly end a finite target before reaching it', () {
    controller.prepareSession();
    controller.setTargetRepCount(8);
    controller.startTracking();
    completeRep(controller, 100);
    controller.endSession();

    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.complete);
    expect(state.summary?.totalReps, 1);
    expect(state.workout.completedSets, hasLength(1));
  });

  test('every implemented exercise keeps target through countdown', () {
    const ready = PlacementResult(PlacementStatus.ready, 'Position ready');
    for (final exercise in [
      ExerciseId.squat,
      ExerciseId.bicepCurl,
      ExerciseId.lateralRaise,
      ExerciseId.shoulderPress,
    ]) {
      controller.prepareSession(exercise: exercise);
      controller.setTargetRepCount(8);
      for (var i = 0; i < 3; i++) {
        controller.acceptPreparationResult(ready);
      }

      final state = container.read(sessionControllerProvider);
      expect(state.selectedExercise, exercise);
      expect(state.phase, SessionPhase.countdown);
      expect(state.targetRepCount, 8);
      controller.reset();
    }
  });

  test('all implemented exercises share automatic countdown', () {
    const ready = PlacementResult(PlacementStatus.ready, 'Position ready');
    for (final exercise in [
      ExerciseId.squat,
      ExerciseId.bicepCurl,
      ExerciseId.lateralRaise,
      ExerciseId.shoulderPress,
    ]) {
      controller.prepareSession(exercise: exercise);
      for (var i = 0; i < 3; i++) {
        controller.acceptPreparationResult(ready);
      }
      final state = container.read(sessionControllerProvider);
      expect(state.selectedExercise, exercise);
      expect(state.phase, SessionPhase.countdown);
      expect(state.countdownValue, 3);
      controller.reset();
    }
  });

  test('pose loss cancels countdown and returns to preparation', () {
    controller.prepareSession();
    const ready = PlacementResult(PlacementStatus.ready, 'Position ready');
    for (var i = 0; i < 3; i++) {
      controller.acceptPreparationResult(ready);
    }

    controller.trackingInterrupted();

    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.preparing);
    expect(state.placementStable, isFalse);
    expect(state.countdownValue, isNull);
  });

  test('pose loss restarts automatic countdown from three', () {
    controller.prepareSession();
    const ready = PlacementResult(PlacementStatus.ready, 'Position ready');
    for (var i = 0; i < 3; i++) {
      controller.acceptPreparationResult(ready);
    }
    controller.advanceCountdown();
    expect(container.read(sessionControllerProvider).countdownValue, 2);

    controller.trackingInterrupted();
    for (var i = 0; i < 3; i++) {
      controller.acceptPreparationResult(ready);
    }

    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.countdown);
    expect(state.countdownValue, 3);
  });

  test('one noisy placement frame does not cancel countdown', () {
    controller.prepareSession();
    const ready = PlacementResult(PlacementStatus.ready, 'Position ready');
    for (var i = 0; i < 3; i++) {
      controller.acceptPreparationResult(ready);
    }
    const lost = PlacementResult(
      PlacementStatus.missingLandmarks,
      'Step into frame',
    );

    controller.acceptPreparationResult(lost);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.countdown,
    );

    controller.acceptPreparationResult(lost);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.preparing,
    );
    expect(container.read(sessionControllerProvider).countdownValue, isNull);
  });

  test('moves through calibration, tracking, and completion', () {
    controller.startTracking();
    completeRep(controller, 100);
    completeRep(controller, 110);
    completeRep(controller, 105);
    expect(container.read(sessionControllerProvider).reps, hasLength(3));
    expect(
      container.read(sessionControllerProvider).reps.map((rep) => rep.status),
      everyElement(RepStatus.calibrating),
    );
    expect(container.read(sessionControllerProvider).baseline!['knee'], 105);

    completeRep(controller, 108);
    expect(
      container.read(sessionControllerProvider).latestFeedback!.status,
      RepStatus.good,
    );
    controller.endSession();

    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.complete);
    expect(state.summary!.totalReps, 4);
    expect(state.summary!.formScorePercent, isNull);
  });

  test('duplicate standing frames cannot record duplicate reps', () {
    controller.startTracking();
    for (var i = 0; i < 10; i++) {
      controller.acceptPoseSample(sample(170));
    }
    expect(container.read(sessionControllerProvider).reps, isEmpty);
    for (var i = 0; i < 10; i++) {
      controller.acceptPoseSample(sample(100));
    }
    for (var i = 0; i < 10; i++) {
      controller.acceptPoseSample(sample(170));
    }
    expect(container.read(sessionControllerProvider).reps, hasLength(1));
  });

  test('scripted squat set records exactly one result per movement', () {
    controller.startTracking();
    for (final bottomAngle in [100.0, 105.0, 100.0, 108.0, 105.0]) {
      completeRep(controller, bottomAngle);
    }

    final reps = container.read(sessionControllerProvider).reps;
    expect(reps, hasLength(5));
    expect(reps.map((rep) => rep.number), [1, 2, 3, 4, 5]);
    expect(
      reps.take(3).map((rep) => rep.status),
      everyElement(RepStatus.calibrating),
    );
  });

  test('low-confidence tracking loss cannot finish an active rep', () {
    controller.startTracking();
    repeatSample(controller, 170);
    repeatSample(controller, 100);
    controller.acceptPoseSample(
      const SquatFrameSample(kneeAngle: 170, side: 'left', confidence: 0.2),
    );

    expect(container.read(sessionControllerProvider).reps, isEmpty);
  });

  test('tracking loss clears stale feedback', () {
    controller.startTracking();
    completeRep(controller, 100);
    expect(container.read(sessionControllerProvider).latestFeedback, isNotNull);

    controller.trackingInterrupted();

    expect(container.read(sessionControllerProvider).latestFeedback, isNull);
  });

  test('one noisy angle cannot create a rep', () {
    controller.startTracking();
    repeatSample(controller, 170);
    controller.acceptPoseSample(sample(100));
    repeatSample(controller, 170);

    expect(container.read(sessionControllerProvider).reps, isEmpty);
  });

  test('tracked side stays locked until rep completes', () {
    controller.startTracking();
    repeatSample(controller, 170, side: 'left');
    repeatSample(controller, 100, side: 'right');
    repeatSample(controller, 170, side: 'right');
    expect(container.read(sessionControllerProvider).reps, isEmpty);

    repeatSample(controller, 100, side: 'left');
    repeatSample(controller, 170, side: 'left');
    expect(container.read(sessionControllerProvider).reps, hasLength(1));
  });

  test('deliberate shallow squat completes and receives range feedback', () {
    controller.startTracking();
    for (var i = 0; i < 3; i++) {
      completeRep(controller, 100);
    }

    completeRep(controller, 145);

    final rep = container.read(sessionControllerProvider).reps.last;
    expect(rep.number, 4);
    expect(rep.angles['knee'], 145);
    expect(rep.metrics!.rangeOfMotion[MovementMetric.kneeAngle], 25);
    expect(rep.status, RepStatus.degraded);
    expect(feedbackForRep(rep), 'Next rep: go lower');
  });

  test('end session stops evaluation and reset clears all state', () {
    controller.startTracking();
    completeRep(controller, 100);
    controller.endSession();
    completeRep(controller, 100);
    expect(container.read(sessionControllerProvider).reps, hasLength(1));

    controller.reset();
    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.idle);
    expect(state.reps, isEmpty);
    expect(state.baseline, isNull);
    expect(state.summary, isNull);
    expect(state.error, isNull);
  });

  test('pipeline failure blocks samples until retry', () {
    controller.startTracking();
    controller.reportFailure('camera failed');
    completeRep(controller, 100);
    expect(container.read(sessionControllerProvider).reps, isEmpty);

    controller.retry();
    completeRep(controller, 100);
    expect(container.read(sessionControllerProvider).error, isNull);
    expect(container.read(sessionControllerProvider).reps, hasLength(1));
  });

  test('low-confidence sample cannot advance coaching or rep state', () {
    controller.startTracking();
    controller.acceptPoseSample(
      const SquatFrameSample(kneeAngle: 170, side: 'left', confidence: 0.2),
    );
    controller.acceptPoseSample(
      const SquatFrameSample(kneeAngle: 100, side: 'left', confidence: 0.9),
    );
    expect(container.read(sessionControllerProvider).coaching, isNull);
    expect(container.read(sessionControllerProvider).reps, isEmpty);
  });

  test('demo thresholds require three deviations beyond twenty degrees', () {
    final evaluator = RepEvaluator(squatExerciseThresholds());
    for (final angle in [100.0, 100.0, 100.0]) {
      evaluator.evaluate({'knee': angle}, confidenceOk: true);
    }
    expect(
      evaluator.evaluate({'knee': 120}, confidenceOk: true)!.status,
      RepStatus.good,
    );
    expect(
      evaluator.evaluate({'knee': 121}, confidenceOk: true)!.status,
      RepStatus.warning,
    );
    expect(
      evaluator.evaluate({'knee': 122}, confidenceOk: true)!.status,
      RepStatus.warning,
    );
    expect(
      evaluator.evaluate({'knee': 123}, confidenceOk: true)!.status,
      RepStatus.degraded,
    );
  });

  test('deep squat is not rejected by an unsupported minimum angle', () {
    final evaluator = RepEvaluator(squatExerciseThresholds());
    for (final angle in [60.0, 60.0, 60.0]) {
      evaluator.evaluate({'knee': angle}, confidenceOk: true);
    }

    expect(
      evaluator.evaluate({'knee': 60}, confidenceOk: true)!.status,
      RepStatus.good,
    );
  });

  test('bicep curl runs through calibration and evaluated rep', () {
    controller.prepareSession(exercise: ExerciseId.bicepCurl);
    controller.startTracking();
    for (var rep = 0; rep < 4; rep++) {
      repeatCurl(controller, 165, 165);
      repeatCurl(controller, 70, 75);
      repeatCurl(controller, 165, 165);
    }

    final state = container.read(sessionControllerProvider);
    expect(state.selectedExercise, ExerciseId.bicepCurl);
    expect(state.reps, hasLength(4));
    expect(
      state.reps.take(3).map((rep) => rep.status),
      everyElement(RepStatus.calibrating),
    );
    expect(state.reps.last.status, RepStatus.good);

    controller.endSession();
    expect(container.read(sessionControllerProvider).summary!.totalReps, 4);
  });

  test('lateral raise uses shared calibration and rep flow', () {
    controller.prepareSession(exercise: ExerciseId.lateralRaise);
    controller.startTracking();
    for (var rep = 0; rep < 4; rep++) {
      repeatLateralRaise(controller, 10, 10);
      repeatLateralRaise(controller, 90, 90);
      repeatLateralRaise(controller, 10, 10);
    }

    final state = container.read(sessionControllerProvider);
    expect(state.selectedExercise, ExerciseId.lateralRaise);
    expect(state.reps, hasLength(4));
    expect(
      state.reps.take(3).map((rep) => rep.status),
      everyElement(RepStatus.calibrating),
    );
    expect(state.reps.last.status, RepStatus.good);
  });

  test('shoulder press uses shared calibration and range feedback', () {
    controller.prepareSession(exercise: ExerciseId.shoulderPress);
    controller.startTracking();
    for (var rep = 0; rep < 3; rep++) {
      repeatShoulderPress(controller, 95, 95, 90);
      repeatShoulderPress(controller, 165, 165, 170);
      repeatShoulderPress(controller, 95, 95, 90);
    }
    repeatShoulderPress(controller, 95, 95, 90);
    repeatShoulderPress(controller, 135, 135, 140);
    repeatShoulderPress(controller, 95, 95, 90);

    final state = container.read(sessionControllerProvider);
    expect(state.reps, hasLength(4));
    expect(
      state.reps.take(3).map((rep) => rep.status),
      everyElement(RepStatus.calibrating),
    );
    expect(state.reps.last.status, RepStatus.degraded);
    expect(feedbackForRep(state.reps.last), 'Press both hands fully overhead');
  });

  test('set completion appends exactly one immutable workout snapshot', () {
    controller.startTracking();
    completeRep(controller, 100);
    controller.endSession();
    controller.endSession();

    final state = container.read(sessionControllerProvider);
    expect(state.workout.completedSets, hasLength(1));
    expect(state.workout.completedSets.single.setNumber, 1);
    expect(state.workout.completedSets.single.exercise, ExerciseId.squat);
    expect(state.workout.completedSets.single.reps, hasLength(1));
  });

  test('next set preserves history and clears reps and baseline', () {
    controller.startTracking();
    for (var rep = 0; rep < 3; rep++) {
      completeRep(controller, 100);
    }
    controller.endSession();
    controller.nextSet();

    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.preparing);
    expect(state.selectedExercise, ExerciseId.squat);
    expect(state.workout.completedSets, hasLength(1));
    expect(state.reps, isEmpty);
    expect(state.baseline, isNull);
  });

  test('change exercise preserves workout and finish/reset are explicit', () {
    controller.startTracking();
    completeRep(controller, 100);
    controller.endSession();
    controller.changeExercise();
    expect(container.read(sessionControllerProvider).phase, SessionPhase.idle);
    expect(
      container.read(sessionControllerProvider).workout.completedSets,
      hasLength(1),
    );

    controller.prepareSession(exercise: ExerciseId.bicepCurl);
    controller.startTracking();
    repeatCurl(controller, 165, 165);
    repeatCurl(controller, 70, 75);
    repeatCurl(controller, 165, 165);
    controller.endSession();
    controller.finishWorkout();

    var state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.workoutComplete);
    expect(state.workout.isFinished, isTrue);
    expect(state.workout.completedSets, hasLength(2));
    expect(state.workout.completedSets.map((set) => set.exercise), [
      ExerciseId.squat,
      ExerciseId.bicepCurl,
    ]);

    controller.reset();
    state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.idle);
    expect(state.workout.completedSets, isEmpty);
  });

  test('finish workout persists once without blocking session state', () async {
    final backend = TestHistoryBackend();
    final localContainer = ProviderContainer(
      overrides: [
        historyStorageProvider.overrideWithValue(HistoryStorage(backend)),
      ],
    );
    addTearDown(localContainer.dispose);
    final local = localContainer.read(sessionControllerProvider.notifier);
    local.startTracking();
    completeRep(local, 100);
    local.endSession();
    local.finishWorkout();
    await Future<void>.delayed(Duration.zero);

    expect(
      localContainer.read(sessionControllerProvider).phase,
      SessionPhase.workoutComplete,
    );
    expect(await HistoryStorage(backend).load(), hasLength(1));
  });
}

void repeatShoulderPress(
  SessionController controller,
  double left,
  double right,
  double elbow,
) {
  for (var i = 0; i < 3; i++) {
    controller.acceptShoulderPressSample(
      LateralRaiseFrameSample(
        leftArmElevation: left,
        rightArmElevation: right,
        leftElbowAngle: elbow,
        rightElbowAngle: elbow,
        torsoLean: 0,
        leftConfidence: 0.9,
        rightConfidence: 0.9,
        torsoConfidence: 0.9,
      ),
    );
  }
}

void repeatLateralRaise(
  SessionController controller,
  double left,
  double right,
) {
  for (var i = 0; i < 3; i++) {
    controller.acceptLateralRaiseSample(
      LateralRaiseFrameSample(
        leftArmElevation: left,
        rightArmElevation: right,
        leftElbowAngle: 165,
        rightElbowAngle: 165,
        torsoLean: 0,
        leftConfidence: 0.9,
        rightConfidence: 0.9,
        torsoConfidence: 0.9,
      ),
    );
  }
}

void repeatCurl(SessionController controller, double left, double right) {
  for (var i = 0; i < 3; i++) {
    controller.acceptBicepCurlSample(
      BicepCurlFrameSample(
        leftElbowAngle: left,
        rightElbowAngle: right,
        leftConfidence: 0.9,
        rightConfidence: 0.9,
        torsoVerticalPosition: 1,
        torsoConfidence: 0.9,
      ),
    );
  }
}

void completeRep(SessionController controller, double bottomAngle) {
  repeatSample(controller, 170);
  repeatSample(controller, bottomAngle);
  repeatSample(controller, 170);
}

void repeatSample(
  SessionController controller,
  double angle, {
  String side = 'left',
}) {
  for (var i = 0; i < 3; i++) {
    controller.acceptPoseSample(sample(angle, side: side));
  }
}

SquatFrameSample sample(double angle, {String side = 'left'}) =>
    SquatFrameSample(kneeAngle: angle, side: side, confidence: 0.9);

class TestHistoryBackend implements HistoryBackend {
  final values = <String, String>{};

  @override
  Future<String?> getString(String key) async => values[key];

  @override
  Future<void> setString(String key, String value) async {
    values[key] = value;
  }
}
