import 'exercise.dart';

enum ShoulderPressPhase { waitingForRack, pressing, returning }

class ShoulderPressRepDetector implements RepDetector {
  ShoulderPressRepDetector({
    this.rackMaximumElevation = 115,
    this.movementStartExcursion = 20,
    this.minimumAttemptExcursion = 30,
    this.maximumTorsoLeanChange = 10,
  });

  final double rackMaximumElevation;
  final double movementStartExcursion;
  final double minimumAttemptExcursion;
  final double maximumTorsoLeanChange;

  ShoulderPressPhase _phase = ShoulderPressPhase.waitingForRack;
  double? _leftStart;
  double? _rightStart;
  double? _leftMaximum;
  double? _rightMaximum;
  double? _leftElbowMaximum;
  double? _rightElbowMaximum;
  double? _startTorso;
  DateTime? _startTime;
  DateTime? _leftPeakTime;
  DateTime? _rightPeakTime;
  double _minimumConfidence = 1;

  @override
  RepCompletion? addFrame(MovementFrame frame) {
    final left = frame.values[MovementMetric.leftArmElevation];
    final right = frame.values[MovementMetric.rightArmElevation];
    final leftElbow = frame.values[MovementMetric.leftElbowAngle];
    final rightElbow = frame.values[MovementMetric.rightElbowAngle];
    final torso = frame.values[MovementMetric.torsoLean];
    final confidence = [
      frame.confidence[MovementMetric.leftArmElevation],
      frame.confidence[MovementMetric.rightArmElevation],
      frame.confidence[MovementMetric.leftElbowAngle],
      frame.confidence[MovementMetric.rightElbowAngle],
      frame.confidence[MovementMetric.torsoLean],
    ];
    if ([
          left,
          right,
          leftElbow,
          rightElbow,
          torso,
        ].any((value) => value == null || !value.isFinite) ||
        confidence.any((value) => value == null || value < 0.6)) {
      reset();
      return null;
    }
    final values = confidence.cast<double>();
    final minimum = values.reduce((a, b) => a < b ? a : b);
    if (minimum < _minimumConfidence) _minimumConfidence = minimum;
    if (_startTorso != null &&
        (torso! - _startTorso!).abs() > maximumTorsoLeanChange) {
      reset();
      return null;
    }
    return switch (_phase) {
      ShoulderPressPhase.waitingForRack => _arm(
        left!,
        right!,
        leftElbow!,
        rightElbow!,
        torso!,
        frame.timestamp,
        minimum,
      ),
      ShoulderPressPhase.pressing => _press(
        left!,
        right!,
        leftElbow!,
        rightElbow!,
        torso!,
        frame.timestamp,
      ),
      ShoulderPressPhase.returning => _return(
        left!,
        right!,
        leftElbow!,
        rightElbow!,
        frame.timestamp,
      ),
    };
  }

  RepCompletion? _arm(
    double left,
    double right,
    double leftElbow,
    double rightElbow,
    double torso,
    DateTime time,
    double confidence,
  ) {
    if (left <= rackMaximumElevation && right <= rackMaximumElevation) {
      _prepare(left, right, leftElbow, rightElbow, torso, time, confidence);
    }
    return null;
  }

  RepCompletion? _press(
    double left,
    double right,
    double leftElbow,
    double rightElbow,
    double torso,
    DateTime time,
  ) {
    if (left <= rackMaximumElevation && right <= rackMaximumElevation) {
      _prepare(
        left,
        right,
        leftElbow,
        rightElbow,
        torso,
        time,
        _minimumConfidence,
      );
      return null;
    }
    if (left - _leftStart! >= movementStartExcursion ||
        right - _rightStart! >= movementStartExcursion) {
      _phase = ShoulderPressPhase.returning;
      _track(left, right, leftElbow, rightElbow, time);
    }
    return null;
  }

  RepCompletion? _return(
    double left,
    double right,
    double leftElbow,
    double rightElbow,
    DateTime time,
  ) {
    _track(left, right, leftElbow, rightElbow, time);
    if (left > rackMaximumElevation || right > rackMaximumElevation) {
      return null;
    }
    final leftStart = _leftStart!;
    final rightStart = _rightStart!;
    final leftMax = _leftMaximum!;
    final rightMax = _rightMaximum!;
    final leftRange = leftMax - leftStart;
    final rightRange = rightMax - rightStart;
    final start = _startTime ?? time;
    final leftPeak = _leftPeakTime ?? start;
    final rightPeak = _rightPeakTime ?? start;
    final peak = leftPeak.isAfter(rightPeak) ? leftPeak : rightPeak;
    final completion = RepCompletion(
      minimumValues: {
        MovementMetric.leftArmElevation: leftStart,
        MovementMetric.rightArmElevation: rightStart,
      },
      maximumValues: {
        MovementMetric.leftArmElevation: leftMax,
        MovementMetric.rightArmElevation: rightMax,
        MovementMetric.leftElbowAngle: _leftElbowMaximum!,
        MovementMetric.rightElbowAngle: _rightElbowMaximum!,
      },
      trackedSide: TrackedSide.bilateral,
      metrics: RepMetrics(
        totalDuration: _duration(time, start),
        outwardDuration: _duration(peak, start),
        returnDuration: _duration(time, peak),
        rangeOfMotion: {
          MovementMetric.leftArmElevation: leftRange,
          MovementMetric.rightArmElevation: rightRange,
        },
        bilateralTimingDifference: _absolute(leftPeak.difference(rightPeak)),
        completionConfidence: _minimumConfidence,
      ),
    );
    final torso = _startTorso ?? 0;
    final confidence = _minimumConfidence;
    _prepare(left, right, leftElbow, rightElbow, torso, time, confidence);
    return leftRange >= minimumAttemptExcursion ||
            rightRange >= minimumAttemptExcursion
        ? completion
        : null;
  }

  void _track(
    double left,
    double right,
    double leftElbow,
    double rightElbow,
    DateTime time,
  ) {
    if (left > (_leftMaximum ?? -double.infinity)) {
      _leftMaximum = left;
      _leftPeakTime = time;
    }
    if (right > (_rightMaximum ?? -double.infinity)) {
      _rightMaximum = right;
      _rightPeakTime = time;
    }
    if (leftElbow > (_leftElbowMaximum ?? -double.infinity)) {
      _leftElbowMaximum = leftElbow;
    }
    if (rightElbow > (_rightElbowMaximum ?? -double.infinity)) {
      _rightElbowMaximum = rightElbow;
    }
  }

  void _prepare(
    double left,
    double right,
    double leftElbow,
    double rightElbow,
    double torso,
    DateTime time,
    double confidence,
  ) {
    _phase = ShoulderPressPhase.pressing;
    _leftStart = left;
    _rightStart = right;
    _leftMaximum = null;
    _rightMaximum = null;
    _leftElbowMaximum = leftElbow;
    _rightElbowMaximum = rightElbow;
    _startTorso = torso;
    _startTime = time;
    _leftPeakTime = null;
    _rightPeakTime = null;
    _minimumConfidence = confidence;
  }

  Duration _duration(DateTime end, DateTime start) {
    final value = end.difference(start);
    return value.isNegative ? Duration.zero : value;
  }

  Duration _absolute(Duration value) => value.isNegative ? -value : value;

  @override
  void reset() {
    _phase = ShoulderPressPhase.waitingForRack;
    _leftStart = null;
    _rightStart = null;
    _leftMaximum = null;
    _rightMaximum = null;
    _leftElbowMaximum = null;
    _rightElbowMaximum = null;
    _startTorso = null;
    _startTime = null;
    _leftPeakTime = null;
    _rightPeakTime = null;
    _minimumConfidence = 1;
  }
}
