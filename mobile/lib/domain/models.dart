enum RepStatus { calibrating, good, warning, degraded }

class JointThreshold {
  const JointThreshold({
    required this.minimum,
    required this.maximum,
    required this.deviationThreshold,
  }) : assert(minimum <= maximum),
       assert(deviationThreshold > 0);

  final double minimum;
  final double maximum;
  final double deviationThreshold;

  bool contains(double angle) => angle >= minimum && angle <= maximum;
}

class ExerciseThresholds {
  ExerciseThresholds({
    required Map<String, JointThreshold> joints,
    this.calibrationRepCount = 3,
    this.persistenceCount = 2,
  }) : assert(joints.isNotEmpty),
       assert(calibrationRepCount > 0),
       assert(persistenceCount > 0),
       joints = Map.unmodifiable(joints);

  final Map<String, JointThreshold> joints;
  final int calibrationRepCount;
  final int persistenceCount;
}

class Rep {
  Rep({
    required this.number,
    required Map<String, double> angles,
    required this.status,
    this.reason,
    this.responsibleJoint,
  }) : angles = Map.unmodifiable(angles);

  final int number;
  final Map<String, double> angles;
  final RepStatus status;
  final String? reason;
  final String? responsibleJoint;
}

class SessionSummary {
  SessionSummary({
    required this.totalReps,
    required this.formScorePercent,
    required this.degradationStartRep,
    required this.primaryResponsibleJoint,
    required List<Rep> repChecklist,
  }) : repChecklist = List.unmodifiable(repChecklist);

  final int totalReps;
  final double? formScorePercent;
  final int? degradationStartRep;
  final String? primaryResponsibleJoint;
  final List<Rep> repChecklist;

  bool get hasEnoughData => formScorePercent != null;
}
