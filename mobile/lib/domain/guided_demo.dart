import 'exercise.dart';

class GuidedDemoCycleTracker {
  GuidedDemoCycleTracker({
    this.targetCycles = 5,
    this.checkInterval = const Duration(seconds: 2),
  });

  final int targetCycles;
  final Duration checkInterval;
  int completedCycles = 0;
  int _lastFrame = -1;
  DateTime? _nextCheckAt;

  bool get isComplete => completedCycles >= targetCycles;

  String? accept({
    required int frame,
    required DateTime checkedAt,
    required String? instruction,
  }) {
    if (isComplete || instruction == null || frame <= _lastFrame) return null;
    if (_nextCheckAt != null && checkedAt.isBefore(_nextCheckAt!)) return null;
    _lastFrame = frame;
    _nextCheckAt = checkedAt.add(checkInterval);
    completedCycles++;
    return instruction;
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
