import 'exercise.dart';

class GuidedDemoRepTracker {
  GuidedDemoRepTracker(this._detector, {this.targetReps = 5});

  final RepDetector _detector;
  final int targetReps;
  int completedReps = 0;
  int _lastFrame = -1;

  bool get isComplete => completedReps >= targetReps;

  bool accept({required int frame, required MovementFrame movement}) {
    if (isComplete || frame <= _lastFrame) return false;
    _lastFrame = frame;
    if (_detector.addFrame(movement) == null) return false;
    completedReps++;
    return true;
  }

  void resetAttempt() {
    _detector.reset();
  }
}

String? guidedDemoInstruction(
  ExerciseId exercise,
  Map<MovementMetric, double> values,
) => switch (exercise) {
  ExerciseId.squat => _squatInstruction(values),
  ExerciseId.bicepCurl => _curlInstruction(values),
  ExerciseId.lateralRaise => _lateralRaiseInstruction(values),
  ExerciseId.shoulderPress => _shoulderPressInstruction(values),
  ExerciseId.reverseLunge || ExerciseId.jumpingJack => null,
};

String? _squatInstruction(Map<MovementMetric, double> values) {
  final knee = values[MovementMetric.kneeAngle];
  if (knee == null || !knee.isFinite) return null;
  return knee < 155
      ? 'Straighten your knees to reach the squat starting position.'
      : 'Knee position ready. Hold your standing position.';
}

String? _curlInstruction(Map<MovementMetric, double> values) {
  final left = values[MovementMetric.leftElbowAngle];
  final right = values[MovementMetric.rightElbowAngle];
  if (left == null || right == null || !left.isFinite || !right.isFinite) {
    return null;
  }
  if ((left - right).abs() > 15) {
    return 'Bring both forearms to the same position.';
  }
  return left < 145 || right < 145
      ? 'Lower both forearms to the curl starting position.'
      : 'Both elbows are ready. Hold your arms lowered.';
}

String? _lateralRaiseInstruction(Map<MovementMetric, double> values) {
  final left = values[MovementMetric.leftArmElevation];
  final right = values[MovementMetric.rightArmElevation];
  if (left == null || right == null || !left.isFinite || !right.isFinite) {
    return null;
  }
  if ((left - right).abs() > 12) return 'Bring both arms to the same height.';
  return left > 25 || right > 25
      ? 'Lower both arms to your sides.'
      : 'Arm position ready. Hold both arms at your sides.';
}

String? _shoulderPressInstruction(Map<MovementMetric, double> values) {
  final left = values[MovementMetric.leftArmElevation];
  final right = values[MovementMetric.rightArmElevation];
  if (left == null || right == null || !left.isFinite || !right.isFinite) {
    return null;
  }
  if ((left - right).abs() > 12) return 'Bring both hands to the same height.';
  return left > 115 || right > 115
      ? 'Lower both hands to shoulder height.'
      : 'Rack position ready. Hold both hands near shoulder height.';
}
