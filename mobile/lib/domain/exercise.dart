enum ExerciseId {
  squat,
  reverseLunge,
  bicepCurl,
  shoulderPress,
  lateralRaise,
  jumpingJack,
}

enum MovementMetric {
  kneeAngle,
  leftKneeAngle,
  rightKneeAngle,
  leftHipAngle,
  rightHipAngle,
  leftElbowAngle,
  rightElbowAngle,
  torsoLean,
  armElevation,
  stanceWidth,
  wristHeightSymmetry,
  ankleHeightSymmetry,
}

enum CameraView { front, slightSide, side, slightDiagonal }

enum TrackedSide { left, right, bilateral, unknown }

enum BodyJoint {
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

class MetricThreshold {
  const MetricThreshold({required this.minimum, required this.maximum})
    : assert(minimum <= maximum);

  final double minimum;
  final double maximum;
}

class ExerciseProfile {
  ExerciseProfile({
    required this.id,
    required this.displayName,
    required this.recommendedView,
    required Set<BodyJoint> requiredLandmarks,
    required Set<MovementMetric> phaseMetrics,
    required Map<MovementMetric, MetricThreshold> thresholds,
    required this.setupInstruction,
    this.minimumConfidence = 0.6,
    this.calibrationRepCount = 3,
    this.persistenceCount = 3,
  }) : requiredLandmarks = Set.unmodifiable(requiredLandmarks),
       phaseMetrics = Set.unmodifiable(phaseMetrics),
       thresholds = Map.unmodifiable(thresholds);

  final ExerciseId id;
  final String displayName;
  final CameraView recommendedView;
  final Set<BodyJoint> requiredLandmarks;
  final Set<MovementMetric> phaseMetrics;
  final Map<MovementMetric, MetricThreshold> thresholds;
  final String setupInstruction;
  final double minimumConfidence;
  final int calibrationRepCount;
  final int persistenceCount;
}

class MovementFrame {
  MovementFrame({
    required this.timestamp,
    required Map<MovementMetric, double> values,
    required Map<MovementMetric, double> confidence,
    required this.trackedSide,
  }) : values = Map.unmodifiable(values),
       confidence = Map.unmodifiable(confidence);

  final DateTime timestamp;
  final Map<MovementMetric, double> values;
  final Map<MovementMetric, double> confidence;
  final TrackedSide trackedSide;
}

class RepCompletion {
  RepCompletion({
    required Map<MovementMetric, double> minimumValues,
    required Map<MovementMetric, double> maximumValues,
    required this.trackedSide,
    required this.metrics,
  }) : minimumValues = Map.unmodifiable(minimumValues),
       maximumValues = Map.unmodifiable(maximumValues);

  final Map<MovementMetric, double> minimumValues;
  final Map<MovementMetric, double> maximumValues;
  final TrackedSide trackedSide;
  final RepMetrics metrics;
}

class RepMetrics {
  RepMetrics({
    required this.totalDuration,
    required this.outwardDuration,
    required this.returnDuration,
    required Map<MovementMetric, double> rangeOfMotion,
    required this.completionConfidence,
    this.transitionDuration,
    this.bilateralTimingDifference,
  }) : assert(!totalDuration.isNegative),
       assert(!outwardDuration.isNegative),
       assert(!returnDuration.isNegative),
       assert(completionConfidence >= 0 && completionConfidence <= 1),
       rangeOfMotion = Map.unmodifiable(rangeOfMotion);

  final Duration totalDuration;
  final Duration outwardDuration;
  final Duration returnDuration;
  final Duration? transitionDuration;
  final Map<MovementMetric, double> rangeOfMotion;
  final Duration? bilateralTimingDifference;
  final double completionConfidence;
}

abstract interface class RepDetector {
  RepCompletion? addFrame(MovementFrame frame);
  void reset();
}

final squatExerciseProfile = ExerciseProfile(
  id: ExerciseId.squat,
  displayName: 'Squat',
  recommendedView: CameraView.slightSide,
  requiredLandmarks: const {
    BodyJoint.leftHip,
    BodyJoint.leftKnee,
    BodyJoint.leftAnkle,
  },
  phaseMetrics: const {MovementMetric.kneeAngle},
  thresholds: const {
    MovementMetric.kneeAngle: MetricThreshold(minimum: 0, maximum: 140),
  },
  setupInstruction:
      'Step back until shoulders, hips, knees, and ankles are visible. Face sideways.',
);
