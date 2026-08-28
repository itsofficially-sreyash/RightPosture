import 'exercise.dart';

enum SquatMovementPhase { waitingForStanding, waitingForBottom, returning }

enum SquatCoaching { standTall, ready, goLower, depthGood, standUp }

class SquatRepCompletion {
  const SquatRepCompletion({
    required this.startAngle,
    required this.minimumAngle,
    required this.metrics,
    this.side = TrackedSide.unknown,
  });

  final double startAngle;
  final double minimumAngle;
  final RepMetrics metrics;
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
  DateTime? _startTime;
  DateTime? _peakTime;
  double _minimumConfidence = 1;
  bool _lastMovementWasDescending = false;
  int _incompleteAttemptCount = 0;

  SquatMovementPhase get phase => _phase;
  int get incompleteAttemptCount => _incompleteAttemptCount;

  @override
  RepCompletion? addFrame(MovementFrame frame) {
    final angle = frame.values[MovementMetric.kneeAngle];
    final confidence = frame.confidence[MovementMetric.kneeAngle];
    if (angle == null || confidence == null) return null;
    if (confidence < 0.6) {
      reset();
      return null;
    }
    final completion = addKneeAngle(
      angle,
      confidenceOk: true,
      side: frame.trackedSide,
      timestamp: frame.timestamp,
      confidence: confidence,
    );
    if (completion == null) return null;
    return RepCompletion(
      minimumValues: {MovementMetric.kneeAngle: completion.minimumAngle},
      maximumValues: {MovementMetric.kneeAngle: completion.startAngle},
      trackedSide: completion.side,
      metrics: completion.metrics,
    );
  }

  SquatRepCompletion? addKneeAngle(
    double angle, {
    required bool confidenceOk,
    TrackedSide side = TrackedSide.unknown,
    DateTime? timestamp,
    double confidence = 1,
  }) {
    if (!confidenceOk || !angle.isFinite) return null;
    final sampleTime = timestamp ?? DateTime.now();
    if (_phase != SquatMovementPhase.waitingForStanding) {
      _minimumConfidence = confidence < _minimumConfidence
          ? confidence
          : _minimumConfidence;
    }
    _lastMovementWasDescending = _lastAngle == null || angle < _lastAngle!;
    final result = switch (_phase) {
      SquatMovementPhase.waitingForStanding => _armFromStanding(
        angle,
        sampleTime,
        confidence,
      ),
      SquatMovementPhase.waitingForBottom => _detectBottom(
        angle,
        sampleTime,
        confidence,
      ),
      SquatMovementPhase.returning => _detectReturn(angle, side, sampleTime),
    };
    _lastAngle = angle;
    return result;
  }

  SquatCoaching coachingFor(double angle) {
    if (!angle.isFinite) return SquatCoaching.standTall;
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

  SquatRepCompletion? _armFromStanding(
    double angle,
    DateTime timestamp,
    double confidence,
  ) {
    if (angle >= standingMinimumAngle) {
      _standingAngle = angle;
      _startTime = timestamp;
      _minimumConfidence = confidence;
      _phase = SquatMovementPhase.waitingForBottom;
    }
    return null;
  }

  SquatRepCompletion? _detectBottom(
    double angle,
    DateTime timestamp,
    double confidence,
  ) {
    if (angle >= standingMinimumAngle) {
      _standingAngle = angle;
      _startTime = timestamp;
      _minimumConfidence = confidence;
      return null;
    }
    final standingAngle = _standingAngle;
    if (standingAngle != null &&
        standingAngle - angle >= movementStartExcursion) {
      _minimumAngle = angle;
      _peakTime = timestamp;
      _phase = SquatMovementPhase.returning;
    }
    return null;
  }

  SquatRepCompletion? _detectReturn(
    double angle,
    TrackedSide side,
    DateTime timestamp,
  ) {
    if (angle < standingMinimumAngle) {
      if (angle < (_minimumAngle ?? double.infinity)) {
        _minimumAngle = angle;
        _peakTime = timestamp;
      }
      return null;
    }
    final startAngle = _standingAngle!;
    final minimumAngle = _minimumAngle!;
    final startTime = _startTime ?? timestamp;
    final peakTime = _peakTime ?? startTime;
    final completionConfidence = _minimumConfidence;
    final excursion = startAngle - minimumAngle;
    _standingAngle = angle;
    _minimumAngle = null;
    _startTime = timestamp;
    _peakTime = null;
    _minimumConfidence = 1;
    _phase = SquatMovementPhase.waitingForBottom;
    if (excursion < minimumAttemptExcursion) {
      _incompleteAttemptCount++;
      return null;
    }
    return SquatRepCompletion(
      startAngle: startAngle,
      minimumAngle: minimumAngle,
      side: side,
      metrics: RepMetrics(
        totalDuration: _nonNegativeDifference(timestamp, startTime),
        outwardDuration: _nonNegativeDifference(peakTime, startTime),
        returnDuration: _nonNegativeDifference(timestamp, peakTime),
        rangeOfMotion: {MovementMetric.kneeAngle: excursion},
        completionConfidence: completionConfidence,
      ),
    );
  }

  Duration _nonNegativeDifference(DateTime end, DateTime start) {
    final duration = end.difference(start);
    return duration.isNegative ? Duration.zero : duration;
  }

  @override
  void reset() {
    _phase = SquatMovementPhase.waitingForStanding;
    _standingAngle = null;
    _minimumAngle = null;
    _lastAngle = null;
    _startTime = null;
    _peakTime = null;
    _minimumConfidence = 1;
    _lastMovementWasDescending = false;
    _incompleteAttemptCount = 0;
  }
}
