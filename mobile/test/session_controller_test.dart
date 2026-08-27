import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/models.dart';
import 'package:right_posture/domain/rep_evaluator.dart';
import 'package:right_posture/pose_landmark_mapper.dart';
import 'package:right_posture/session_controller.dart';

void main() {
  late ProviderContainer container;
  late SessionController controller;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
    controller = container.read(sessionControllerProvider.notifier);
  });

  test('moves through calibration, tracking, and completion', () {
    controller.startSession();
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
    expect(state.summary!.formScorePercent, 100);
  });

  test('duplicate standing frames cannot record duplicate reps', () {
    controller.startSession();
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
    controller.startSession();
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
    controller.startSession();
    repeatSample(controller, 170);
    repeatSample(controller, 100);
    controller.acceptPoseSample(
      const SquatFrameSample(kneeAngle: 170, side: 'left', confidence: 0.2),
    );

    expect(container.read(sessionControllerProvider).reps, isEmpty);
  });

  test('one noisy angle cannot create a rep', () {
    controller.startSession();
    repeatSample(controller, 170);
    controller.acceptPoseSample(sample(100));
    repeatSample(controller, 170);

    expect(container.read(sessionControllerProvider).reps, isEmpty);
  });

  test('tracked side stays locked until rep completes', () {
    controller.startSession();
    repeatSample(controller, 170, side: 'left');
    repeatSample(controller, 100, side: 'right');
    repeatSample(controller, 170, side: 'right');
    expect(container.read(sessionControllerProvider).reps, isEmpty);

    repeatSample(controller, 100, side: 'left');
    repeatSample(controller, 170, side: 'left');
    expect(container.read(sessionControllerProvider).reps, hasLength(1));
  });

  test('deliberate shallow squat completes and receives range feedback', () {
    controller.startSession();
    for (var i = 0; i < 3; i++) {
      completeRep(controller, 100);
    }

    completeRep(controller, 145);

    final rep = container.read(sessionControllerProvider).reps.last;
    expect(rep.number, 4);
    expect(rep.angles['knee'], 145);
    expect(rep.status, RepStatus.degraded);
    expect(rep.reason, 'Next rep: go lower');
  });

  test('end session stops evaluation and reset clears all state', () {
    controller.startSession();
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
    controller.startSession();
    controller.reportFailure('camera failed');
    completeRep(controller, 100);
    expect(container.read(sessionControllerProvider).reps, isEmpty);

    controller.retry();
    completeRep(controller, 100);
    expect(container.read(sessionControllerProvider).error, isNull);
    expect(container.read(sessionControllerProvider).reps, hasLength(1));
  });

  test('low-confidence sample cannot advance coaching or rep state', () {
    controller.startSession();
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
