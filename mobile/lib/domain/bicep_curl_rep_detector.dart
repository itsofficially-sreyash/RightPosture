import 'exercise.dart';

enum BicepCurlPhase { waitingForExtension, curling, returning }

class BicepCurlRepDetector implements RepDetector {
  BicepCurlRepDetector({
    this.extensionMinimumAngle = 150,
    this.movementStartExcursion = 15,
    this.minimumAttemptExcursion = 25,
    this.maximumTorsoShift = 0.35,
  });

  final double extensionMinimumAngle;
  final double movementStartExcursion;
  final double minimumAttemptExcursion;
  final double maximumTorsoShift;

  BicepCurlPhase _phase = BicepCurlPhase.waitingForExtension;
  double? _leftStart;
  double? _rightStart;
  double? _leftMinimum;
  double? _rightMinimum;
  DateTime? _startTime;
  DateTime? _leftPeakTime;
  DateTime? _rightPeakTime;
  double _minimumConfidence = 1;
  double? _startTorsoPosition;

  BicepCurlPhase get phase => _phase;

  @override
  RepCompletion? addFrame(MovementFrame frame) {
    final left = frame.values[MovementMetric.leftElbowAngle];
    final right = frame.values[MovementMetric.rightElbowAngle];
    final leftConfidence = frame.confidence[MovementMetric.leftElbowAngle];
    final rightConfidence = frame.confidence[MovementMetric.rightElbowAngle];
    final torso = frame.values[MovementMetric.torsoVerticalPosition];
    final torsoConfidence =
        frame.confidence[MovementMetric.torsoVerticalPosition];
    if (left == null ||
        right == null ||
        leftConfidence == null ||
        rightConfidence == null ||
        torso == null ||
        torsoConfidence == null ||
        !left.isFinite ||
        !right.isFinite ||
        leftConfidence < 0.6 ||
        rightConfidence < 0.6) {
      reset();
      return null;
    }
    if (torsoConfidence < 0.6) {
      reset();
      return null;
    }
    final confidence = leftConfidence < rightConfidence
        ? leftConfidence
        : rightConfidence;
    _minimumConfidence = confidence < _minimumConfidence
        ? confidence
        : _minimumConfidence;

    return switch (_phase) {
      BicepCurlPhase.waitingForExtension => _arm(
        left,
        right,
        torso,
        frame.timestamp,
        confidence,
      ),
      BicepCurlPhase.curling => _trackCurl(left, right, torso, frame.timestamp),
      BicepCurlPhase.returning => _complete(
        left,
        right,
        torso,
        frame.timestamp,
      ),
    };
  }

  RepCompletion? _arm(
    double left,
    double right,
    double torso,
    DateTime timestamp,
    double confidence,
  ) {
    if (left >= extensionMinimumAngle && right >= extensionMinimumAngle) {
      _leftStart = left;
      _rightStart = right;
      _startTime = timestamp;
      _startTorsoPosition = torso;
      _minimumConfidence = confidence;
      _phase = BicepCurlPhase.curling;
    }
    return null;
  }

  RepCompletion? _trackCurl(
    double left,
    double right,
    double torso,
    DateTime timestamp,
  ) {
    if (_torsoMoved(torso)) {
      reset();
      return null;
    }
    if (left >= extensionMinimumAngle && right >= extensionMinimumAngle) {
      _leftStart = left;
      _rightStart = right;
      _startTime = timestamp;
      _startTorsoPosition = torso;
      return null;
    }
    if (_leftStart! - left >= movementStartExcursion ||
        _rightStart! - right >= movementStartExcursion) {
      _leftMinimum = left;
      _rightMinimum = right;
      _leftPeakTime = timestamp;
      _rightPeakTime = timestamp;
      _phase = BicepCurlPhase.returning;
    }
    return null;
  }

  RepCompletion? _complete(
    double left,
    double right,
    double torso,
    DateTime timestamp,
  ) {
    if (_torsoMoved(torso)) {
      reset();
      return null;
    }
    if (left < (_leftMinimum ?? double.infinity)) {
      _leftMinimum = left;
      _leftPeakTime = timestamp;
    }
    if (right < (_rightMinimum ?? double.infinity)) {
      _rightMinimum = right;
      _rightPeakTime = timestamp;
    }
    if (left < extensionMinimumAngle || right < extensionMinimumAngle) {
      return null;
    }

    final leftStart = _leftStart!;
    final rightStart = _rightStart!;
    final leftMinimum = _leftMinimum!;
    final rightMinimum = _rightMinimum!;
    final leftRange = leftStart - leftMinimum;
    final rightRange = rightStart - rightMinimum;
    final startTime = _startTime ?? timestamp;
    final leftPeak = _leftPeakTime ?? startTime;
    final rightPeak = _rightPeakTime ?? startTime;
    final peak = leftPeak.isAfter(rightPeak) ? leftPeak : rightPeak;
    final confidence = _minimumConfidence;
    _prepareNext(left, right, torso, timestamp);
    if (leftRange < minimumAttemptExcursion &&
        rightRange < minimumAttemptExcursion) {
      return null;
    }
    return RepCompletion(
      minimumValues: {
        MovementMetric.leftElbowAngle: leftMinimum,
        MovementMetric.rightElbowAngle: rightMinimum,
      },
      maximumValues: {
        MovementMetric.leftElbowAngle: leftStart,
        MovementMetric.rightElbowAngle: rightStart,
      },
      trackedSide: TrackedSide.bilateral,
      metrics: RepMetrics(
        totalDuration: _difference(timestamp, startTime),
        outwardDuration: _difference(peak, startTime),
        returnDuration: _difference(timestamp, peak),
        rangeOfMotion: {
          MovementMetric.leftElbowAngle: leftRange,
          MovementMetric.rightElbowAngle: rightRange,
        },
        bilateralTimingDifference: _absoluteDifference(leftPeak, rightPeak),
        completionConfidence: confidence,
      ),
    );
  }

  bool _torsoMoved(double position) =>
      (position - (_startTorsoPosition ?? position)).abs() > maximumTorsoShift;

  void _prepareNext(
    double left,
    double right,
    double torso,
    DateTime timestamp,
  ) {
    _phase = BicepCurlPhase.curling;
    _leftStart = left;
    _rightStart = right;
    _leftMinimum = null;
    _rightMinimum = null;
    _startTime = timestamp;
    _leftPeakTime = null;
    _rightPeakTime = null;
    _minimumConfidence = 1;
    _startTorsoPosition = torso;
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
    _phase = BicepCurlPhase.waitingForExtension;
    _leftStart = null;
    _rightStart = null;
    _leftMinimum = null;
    _rightMinimum = null;
    _startTime = null;
    _leftPeakTime = null;
    _rightPeakTime = null;
    _minimumConfidence = 1;
    _startTorsoPosition = null;
  }
}
