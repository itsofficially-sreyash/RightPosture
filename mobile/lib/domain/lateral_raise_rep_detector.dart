import 'exercise.dart';

enum LateralRaisePhase { waitingForArmsDown, raising, lowering }

class LateralRaiseRepDetector implements RepDetector {
  LateralRaiseRepDetector({
    this.downMaximumElevation = 20,
    this.movementStartExcursion = 15,
    this.minimumAttemptExcursion = 25,
    this.maximumTorsoLeanChange = 10,
  });

  final double downMaximumElevation;
  final double movementStartExcursion;
  final double minimumAttemptExcursion;
  final double maximumTorsoLeanChange;

  LateralRaisePhase _phase = LateralRaisePhase.waitingForArmsDown;
  double? _leftStart;
  double? _rightStart;
  double? _leftMaximum;
  double? _rightMaximum;
  double? _leftElbowMinimum;
  double? _rightElbowMinimum;
  double? _startTorsoLean;
  DateTime? _startTime;
  DateTime? _leftPeakTime;
  DateTime? _rightPeakTime;
  double _minimumConfidence = 1;

  LateralRaisePhase get phase => _phase;

  @override
  RepCompletion? addFrame(MovementFrame frame) {
    final left = frame.values[MovementMetric.leftArmElevation];
    final right = frame.values[MovementMetric.rightArmElevation];
    final torso = frame.values[MovementMetric.torsoLean];
    final leftElbow = frame.values[MovementMetric.leftElbowAngle];
    final rightElbow = frame.values[MovementMetric.rightElbowAngle];
    final confidences = [
      frame.confidence[MovementMetric.leftArmElevation],
      frame.confidence[MovementMetric.rightArmElevation],
      frame.confidence[MovementMetric.torsoLean],
      frame.confidence[MovementMetric.leftElbowAngle],
      frame.confidence[MovementMetric.rightElbowAngle],
    ];
    if (left == null ||
        right == null ||
        torso == null ||
        leftElbow == null ||
        rightElbow == null ||
        !left.isFinite ||
        !right.isFinite ||
        !torso.isFinite ||
        !leftElbow.isFinite ||
        !rightElbow.isFinite ||
        confidences.any((value) => value == null || value < 0.6)) {
      reset();
      return null;
    }
    final confidence = confidences.cast<double>().reduce(
      (a, b) => a < b ? a : b,
    );
    _minimumConfidence = confidence < _minimumConfidence
        ? confidence
        : _minimumConfidence;
    if (_startTorsoLean != null &&
        (torso - _startTorsoLean!).abs() > maximumTorsoLeanChange) {
      reset();
      return null;
    }

    return switch (_phase) {
      LateralRaisePhase.waitingForArmsDown => _arm(
        left,
        right,
        torso,
        leftElbow,
        rightElbow,
        frame.timestamp,
        confidence,
      ),
      LateralRaisePhase.raising => _trackRaise(
        left,
        right,
        torso,
        leftElbow,
        rightElbow,
        frame.timestamp,
      ),
      LateralRaisePhase.lowering => _complete(
        left,
        right,
        leftElbow,
        rightElbow,
        frame.timestamp,
      ),
    };
  }

  RepCompletion? _arm(
    double left,
    double right,
    double torso,
    double leftElbow,
    double rightElbow,
    DateTime timestamp,
    double confidence,
  ) {
    if (left <= downMaximumElevation && right <= downMaximumElevation) {
      _prepareNext(
        left,
        right,
        leftElbow,
        rightElbow,
        torso,
        timestamp,
        confidence,
      );
    }
    return null;
  }

  RepCompletion? _trackRaise(
    double left,
    double right,
    double torso,
    double leftElbow,
    double rightElbow,
    DateTime timestamp,
  ) {
    if (left <= downMaximumElevation && right <= downMaximumElevation) {
      _prepareNext(
        left,
        right,
        leftElbow,
        rightElbow,
        torso,
        timestamp,
        _minimumConfidence,
      );
      return null;
    }
    _trackElbows(leftElbow, rightElbow);
    if (left - _leftStart! >= movementStartExcursion ||
        right - _rightStart! >= movementStartExcursion) {
      _leftMaximum = left;
      _rightMaximum = right;
      _leftPeakTime = timestamp;
      _rightPeakTime = timestamp;
      _phase = LateralRaisePhase.lowering;
    }
    return null;
  }

  RepCompletion? _complete(
    double left,
    double right,
    double leftElbow,
    double rightElbow,
    DateTime timestamp,
  ) {
    _trackElbows(leftElbow, rightElbow);
    if (left > (_leftMaximum ?? -double.infinity)) {
      _leftMaximum = left;
      _leftPeakTime = timestamp;
    }
    if (right > (_rightMaximum ?? -double.infinity)) {
      _rightMaximum = right;
      _rightPeakTime = timestamp;
    }
    if (left > downMaximumElevation || right > downMaximumElevation) {
      return null;
    }
    final leftStart = _leftStart!;
    final rightStart = _rightStart!;
    final leftMaximum = _leftMaximum!;
    final rightMaximum = _rightMaximum!;
    final leftRange = leftMaximum - leftStart;
    final rightRange = rightMaximum - rightStart;
    final startTime = _startTime ?? timestamp;
    final leftPeak = _leftPeakTime ?? startTime;
    final rightPeak = _rightPeakTime ?? startTime;
    final peak = leftPeak.isAfter(rightPeak) ? leftPeak : rightPeak;
    final confidence = _minimumConfidence;
    final torso = _startTorsoLean ?? 0;
    final leftElbowMinimum = _leftElbowMinimum!;
    final rightElbowMinimum = _rightElbowMinimum!;
    _prepareNext(
      left,
      right,
      leftElbow,
      rightElbow,
      torso,
      timestamp,
      confidence,
    );
    if (leftRange < minimumAttemptExcursion &&
        rightRange < minimumAttemptExcursion) {
      return null;
    }
    return RepCompletion(
      minimumValues: {
        MovementMetric.leftArmElevation: leftStart,
        MovementMetric.rightArmElevation: rightStart,
        MovementMetric.leftElbowAngle: leftElbowMinimum,
        MovementMetric.rightElbowAngle: rightElbowMinimum,
      },
      maximumValues: {
        MovementMetric.leftArmElevation: leftMaximum,
        MovementMetric.rightArmElevation: rightMaximum,
      },
      trackedSide: TrackedSide.bilateral,
      metrics: RepMetrics(
        totalDuration: _difference(timestamp, startTime),
        outwardDuration: _difference(peak, startTime),
        returnDuration: _difference(timestamp, peak),
        rangeOfMotion: {
          MovementMetric.leftArmElevation: leftRange,
          MovementMetric.rightArmElevation: rightRange,
        },
        bilateralTimingDifference: _absoluteDifference(leftPeak, rightPeak),
        completionConfidence: confidence,
      ),
    );
  }

  void _prepareNext(
    double left,
    double right,
    double leftElbow,
    double rightElbow,
    double torso,
    DateTime timestamp,
    double confidence,
  ) {
    _phase = LateralRaisePhase.raising;
    _leftStart = left;
    _rightStart = right;
    _leftMaximum = null;
    _rightMaximum = null;
    _leftElbowMinimum = leftElbow;
    _rightElbowMinimum = rightElbow;
    _startTorsoLean = torso;
    _startTime = timestamp;
    _leftPeakTime = null;
    _rightPeakTime = null;
    _minimumConfidence = confidence;
  }

  void _trackElbows(double left, double right) {
    if (left < (_leftElbowMinimum ?? double.infinity)) {
      _leftElbowMinimum = left;
    }
    if (right < (_rightElbowMinimum ?? double.infinity)) {
      _rightElbowMinimum = right;
    }
  }

  Duration _difference(DateTime end, DateTime start) {
    final result = end.difference(start);
    return result.isNegative ? Duration.zero : result;
  }

  Duration _absoluteDifference(DateTime first, DateTime second) {
    final result = first.difference(second);
    return result.isNegative ? -result : result;
  }

  @override
  void reset() {
    _phase = LateralRaisePhase.waitingForArmsDown;
    _leftStart = null;
    _rightStart = null;
    _leftMaximum = null;
    _rightMaximum = null;
    _leftElbowMinimum = null;
    _rightElbowMinimum = null;
    _startTorsoLean = null;
    _startTime = null;
    _leftPeakTime = null;
    _rightPeakTime = null;
    _minimumConfidence = 1;
  }
}
