import 'exercise.dart';

enum SquatMovementPhase { waitingForStanding, waitingForBottom, returning }

enum SquatCoaching { standTall, ready, goLower, depthGood, standUp, tooDeep }

class SquatRepCompletion {
  const SquatRepCompletion({
    required this.startAngle,
    required this.minimumAngle,
    this.side = TrackedSide.unknown,
  });

  final double startAngle;
  final double minimumAngle;
  final TrackedSide side;

  double get excursion => startAngle - minimumAngle;
}

class SquatRepDetector implements RepDetector {
  SquatRepDetector({
    this.bottomMaximumAngle = 110,
    this.standingMinimumAngle = 160,
    this.movementStartExcursion = 10,
    this.minimumAttemptExcursion = 25,
  }) : assert(bottomMaximumAngle < standingMinimumAngle),
       assert(movementStartExcursion > 0),
       assert(minimumAttemptExcursion >= movementStartExcursion);

  final double bottomMaximumAngle;
  final double standingMinimumAngle;
  final double movementStartExcursion;
  final double minimumAttemptExcursion;
  SquatMovementPhase _phase = SquatMovementPhase.waitingForStanding;
  double? _standingAngle;
  double? _minimumAngle;
  double? _lastAngle;
  bool _lastMovementWasDescending = false;
  int _incompleteAttemptCount = 0;

  SquatMovementPhase get phase => _phase;
  int get incompleteAttemptCount => _incompleteAttemptCount;

  @override
  RepCompletion? addFrame(MovementFrame frame) {
    final angle = frame.values[MovementMetric.kneeAngle];
    final confidence = frame.confidence[MovementMetric.kneeAngle];
    if (angle == null || confidence == null) return null;
    final completion = addKneeAngle(
      angle,
      confidenceOk: confidence >= 0.6,
      side: frame.trackedSide,
    );
    if (completion == null) return null;
    return RepCompletion(
      minimumValues: {MovementMetric.kneeAngle: completion.minimumAngle},
      maximumValues: {MovementMetric.kneeAngle: completion.startAngle},
      trackedSide: completion.side,
    );
  }

  SquatRepCompletion? addKneeAngle(
    double angle, {
    required bool confidenceOk,
    TrackedSide side = TrackedSide.unknown,
  }) {
    if (!confidenceOk || !angle.isFinite) return null;
    _lastMovementWasDescending = _lastAngle == null || angle < _lastAngle!;
    final result = switch (_phase) {
      SquatMovementPhase.waitingForStanding => _armFromStanding(angle),
      SquatMovementPhase.waitingForBottom => _detectBottom(angle),
      SquatMovementPhase.returning => _detectReturn(angle, side),
    };
    _lastAngle = angle;
    return result;
  }

  SquatCoaching coachingFor(double angle) {
    if (!angle.isFinite) return SquatCoaching.standTall;
    if (angle < 70) return SquatCoaching.tooDeep;
    return switch (_phase) {
      SquatMovementPhase.waitingForStanding =>
        angle >= standingMinimumAngle
            ? SquatCoaching.ready
            : SquatCoaching.standTall,
      SquatMovementPhase.waitingForBottom =>
        angle >= standingMinimumAngle
            ? SquatCoaching.ready
            : SquatCoaching.goLower,
      SquatMovementPhase.returning =>
        angle <= bottomMaximumAngle
            ? SquatCoaching.depthGood
            : _isDescending(angle)
            ? SquatCoaching.goLower
            : SquatCoaching.standUp,
    };
  }

  bool _isDescending(double angle) {
    final lastAngle = _lastAngle;
    if (lastAngle == null || angle == lastAngle) {
      return _lastMovementWasDescending;
    }
    return angle < lastAngle;
  }

  SquatRepCompletion? _armFromStanding(double angle) {
    if (angle >= standingMinimumAngle) {
      _standingAngle = angle;
      _phase = SquatMovementPhase.waitingForBottom;
    }
    return null;
  }

  SquatRepCompletion? _detectBottom(double angle) {
    if (angle >= standingMinimumAngle) {
      _standingAngle = angle;
      return null;
    }
    final standingAngle = _standingAngle;
    if (standingAngle != null &&
        standingAngle - angle >= movementStartExcursion) {
      _minimumAngle = angle;
      _phase = SquatMovementPhase.returning;
    }
    return null;
  }

  SquatRepCompletion? _detectReturn(double angle, TrackedSide side) {
    if (angle < standingMinimumAngle) {
      if (angle < (_minimumAngle ?? double.infinity)) _minimumAngle = angle;
      return null;
    }
    final startAngle = _standingAngle!;
    final minimumAngle = _minimumAngle!;
    final excursion = startAngle - minimumAngle;
    _standingAngle = angle;
    _minimumAngle = null;
    _phase = SquatMovementPhase.waitingForBottom;
    if (excursion < minimumAttemptExcursion) {
      _incompleteAttemptCount++;
      return null;
    }
    return SquatRepCompletion(
      startAngle: startAngle,
      minimumAngle: minimumAngle,
      side: side,
    );
  }

  @override
  void reset() {
    _phase = SquatMovementPhase.waitingForStanding;
    _standingAngle = null;
    _minimumAngle = null;
    _lastAngle = null;
    _lastMovementWasDescending = false;
    _incompleteAttemptCount = 0;
  }
}
