import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/models.dart';
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
}

void completeRep(SessionController controller, double bottomAngle) {
  controller.acceptPoseSample(sample(170));
  controller.acceptPoseSample(sample(bottomAngle));
  controller.acceptPoseSample(sample(170));
}

SquatFrameSample sample(double angle) =>
    SquatFrameSample(kneeAngle: angle, side: 'left', confidence: 0.9);
