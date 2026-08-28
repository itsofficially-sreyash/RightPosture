import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/shoulder_press_rep_detector.dart';

void main() {
  test('counts bilateral rack-overhead-rack once', () {
    final detector = ShoulderPressRepDetector();
    final start = DateTime(2026);

    expect(detector.addFrame(frame(start, 95, 95, 90)), isNull);
    expect(
      detector.addFrame(
        frame(start.add(const Duration(seconds: 1)), 165, 160, 170),
      ),
      isNull,
    );
    final rep = detector.addFrame(
      frame(start.add(const Duration(seconds: 2)), 95, 95, 90),
    );

    expect(rep, isNotNull);
    expect(rep!.maximumValues[MovementMetric.leftArmElevation], 165);
    expect(rep.maximumValues[MovementMetric.leftElbowAngle], 170);
    expect(rep.trackedSide, TrackedSide.bilateral);
  });

  test('both hands must return before completion', () {
    final detector = ShoulderPressRepDetector();
    final start = DateTime(2026);
    detector.addFrame(frame(start, 95, 95, 90));
    detector.addFrame(
      frame(start.add(const Duration(seconds: 1)), 165, 165, 170),
    );

    expect(
      detector.addFrame(
        frame(start.add(const Duration(seconds: 2)), 95, 140, 100),
      ),
      isNull,
    );
    expect(
      detector.addFrame(
        frame(start.add(const Duration(seconds: 3)), 95, 95, 90),
      ),
      isNotNull,
    );
  });

  test('incomplete overhead attempt still returns range evidence', () {
    final detector = ShoulderPressRepDetector();
    final start = DateTime(2026);
    detector.addFrame(frame(start, 95, 95, 90));
    detector.addFrame(
      frame(start.add(const Duration(seconds: 1)), 135, 135, 140),
    );
    final rep = detector.addFrame(
      frame(start.add(const Duration(seconds: 2)), 95, 95, 90),
    );

    expect(rep, isNotNull);
    expect(rep!.maximumValues[MovementMetric.leftArmElevation], 135);
  });

  test('torso instability invalidates press', () {
    final detector = ShoulderPressRepDetector();
    final start = DateTime(2026);
    detector.addFrame(frame(start, 95, 95, 90));
    detector.addFrame(
      frame(start.add(const Duration(seconds: 1)), 165, 165, 170, torso: 20),
    );
    expect(
      detector.addFrame(
        frame(start.add(const Duration(seconds: 2)), 95, 95, 90),
      ),
      isNull,
    );
  });
}

MovementFrame frame(
  DateTime timestamp,
  double left,
  double right,
  double elbow, {
  double torso = 0,
}) => MovementFrame(
  timestamp: timestamp,
  values: {
    MovementMetric.leftArmElevation: left,
    MovementMetric.rightArmElevation: right,
    MovementMetric.leftElbowAngle: elbow,
    MovementMetric.rightElbowAngle: elbow,
    MovementMetric.torsoLean: torso,
  },
  confidence: const {
    MovementMetric.leftArmElevation: 0.9,
    MovementMetric.rightArmElevation: 0.9,
    MovementMetric.leftElbowAngle: 0.9,
    MovementMetric.rightElbowAngle: 0.9,
    MovementMetric.torsoLean: 0.9,
  },
  trackedSide: TrackedSide.bilateral,
);
