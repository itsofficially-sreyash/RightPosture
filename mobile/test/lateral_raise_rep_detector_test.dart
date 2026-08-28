import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/exercise.dart';
import 'package:right_posture/domain/lateral_raise_rep_detector.dart';

void main() {
  test('counts one bilateral raise and records range and elbow evidence', () {
    final detector = LateralRaiseRepDetector();
    final start = DateTime(2026);

    expect(detector.addFrame(frame(start, 10, 10)), isNull);
    expect(
      detector.addFrame(frame(start.add(const Duration(seconds: 1)), 90, 88)),
      isNull,
    );
    final rep = detector.addFrame(
      frame(start.add(const Duration(seconds: 2)), 10, 10),
    );

    expect(rep, isNotNull);
    expect(rep!.trackedSide, TrackedSide.bilateral);
    expect(rep.metrics.rangeOfMotion[MovementMetric.leftArmElevation], 80);
    expect(rep.metrics.rangeOfMotion[MovementMetric.rightArmElevation], 78);
    expect(rep.minimumValues[MovementMetric.leftElbowAngle], 165);
  });

  test('requires both arms to return before completing', () {
    final detector = LateralRaiseRepDetector();
    final start = DateTime(2026);

    detector.addFrame(frame(start, 10, 10));
    detector.addFrame(frame(start.add(const Duration(seconds: 1)), 90, 90));

    expect(
      detector.addFrame(frame(start.add(const Duration(seconds: 2)), 10, 50)),
      isNull,
    );
    expect(
      detector.addFrame(frame(start.add(const Duration(seconds: 3)), 10, 10)),
      isNotNull,
    );
  });

  test('low confidence invalidates active raise', () {
    final detector = LateralRaiseRepDetector();
    final start = DateTime(2026);

    detector.addFrame(frame(start, 10, 10));
    detector.addFrame(frame(start.add(const Duration(seconds: 1)), 90, 90));
    detector.addFrame(
      frame(start.add(const Duration(seconds: 2)), 10, 10, confidence: 0.2),
    );

    expect(
      detector.addFrame(frame(start.add(const Duration(seconds: 3)), 10, 10)),
      isNull,
    );
  });

  test('torso movement invalidates active raise', () {
    final detector = LateralRaiseRepDetector();
    final start = DateTime(2026);

    detector.addFrame(frame(start, 10, 10));
    detector.addFrame(
      frame(start.add(const Duration(seconds: 1)), 90, 90, torso: 20),
    );
    expect(
      detector.addFrame(frame(start.add(const Duration(seconds: 2)), 10, 10)),
      isNull,
    );
  });
}

MovementFrame frame(
  DateTime timestamp,
  double left,
  double right, {
  double confidence = 0.9,
  double torso = 0,
}) => MovementFrame(
  timestamp: timestamp,
  values: {
    MovementMetric.leftArmElevation: left,
    MovementMetric.rightArmElevation: right,
    MovementMetric.leftElbowAngle: 165,
    MovementMetric.rightElbowAngle: 165,
    MovementMetric.torsoLean: torso,
  },
  confidence: {
    MovementMetric.leftArmElevation: confidence,
    MovementMetric.rightArmElevation: confidence,
    MovementMetric.leftElbowAngle: confidence,
    MovementMetric.rightElbowAngle: confidence,
    MovementMetric.torsoLean: confidence,
  },
  trackedSide: TrackedSide.bilateral,
);
