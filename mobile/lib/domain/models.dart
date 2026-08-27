import 'exercise.dart';

enum RepStatus { calibrating, good, warning, degraded }

enum IssueDirection { belowRange, aboveRange, increased, decreased, asymmetric }

class RepIssue {
  const RepIssue({
    required this.exercise,
    required this.metric,
    required this.direction,
    required this.measuredValue,
    required this.normalizedSeverity,
    this.baselineValue,
  });

  final ExerciseId exercise;
  final MovementMetric metric;
  final IssueDirection direction;
  final double measuredValue;
  final double? baselineValue;
  final double normalizedSeverity;
}

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
    List<RepIssue> issues = const [],
  }) : angles = Map.unmodifiable(angles),
       issues = List.unmodifiable(issues);

  final int number;
  final Map<String, double> angles;
  final RepStatus status;
  final List<RepIssue> issues;
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
