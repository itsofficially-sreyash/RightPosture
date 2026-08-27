import 'models.dart';

class RepEvaluator {
  RepEvaluator(this.thresholds);

  final ExerciseThresholds thresholds;
  final List<Map<String, double>> _calibrationSamples = [];
  final Map<String, int> _deviationCounts = {};
  Map<String, double>? _baseline;
  int _repNumber = 0;

  Map<String, double>? get baseline =>
      _baseline == null ? null : Map<String, double>.unmodifiable(_baseline!);

  Rep? evaluate(Map<String, double> angles, {required bool confidenceOk}) {
    if (!confidenceOk || !_hasEveryTrackedJoint(angles)) return null;
    _repNumber++;

    if (_baseline == null) {
      _calibrationSamples.add(Map<String, double>.from(angles));
      if (_calibrationSamples.length == thresholds.calibrationRepCount) {
        _baseline = {
          for (final joint in thresholds.joints.keys)
            joint: _median(_calibrationSamples.map((sample) => sample[joint]!)),
        };
      }
      return Rep(
        number: _repNumber,
        angles: Map.unmodifiable(angles),
        status: RepStatus.calibrating,
      );
    }

    final absoluteFailure = _largestAbsoluteFailure(angles);
    if (absoluteFailure != null) {
      _deviationCounts.clear();
      return Rep(
        number: _repNumber,
        angles: Map.unmodifiable(angles),
        status: RepStatus.degraded,
        responsibleJoint: absoluteFailure,
        reason: absoluteFailure == 'knee'
            ? angles[absoluteFailure]! <
                      thresholds.joints[absoluteFailure]!.minimum
                  ? 'Next rep: do not go as deep'
                  : 'Next rep: go lower'
            : '$absoluteFailure angle outside acceptable range',
      );
    }

    String? largestDeviationJoint;
    var largestDeviationRatio = 0.0;
    for (final entry in thresholds.joints.entries) {
      final joint = entry.key;
      final deviation = (angles[joint]! - _baseline![joint]!).abs();
      if (deviation > entry.value.deviationThreshold) {
        _deviationCounts[joint] = (_deviationCounts[joint] ?? 0) + 1;
        final ratio = deviation / entry.value.deviationThreshold;
        if (ratio > largestDeviationRatio) {
          largestDeviationRatio = ratio;
          largestDeviationJoint = joint;
        }
      } else {
        _deviationCounts[joint] = 0;
      }
    }

    if (largestDeviationJoint == null) {
      return Rep(
        number: _repNumber,
        angles: Map.unmodifiable(angles),
        status: RepStatus.good,
      );
    }
    final count = _deviationCounts[largestDeviationJoint]!;
    final status = count >= thresholds.persistenceCount
        ? RepStatus.degraded
        : RepStatus.warning;
    return Rep(
      number: _repNumber,
      angles: Map.unmodifiable(angles),
      status: status,
      responsibleJoint: largestDeviationJoint,
      reason: _directionalReason(
        joint: largestDeviationJoint,
        angle: angles[largestDeviationJoint]!,
      ),
    );
  }

  String _directionalReason({required String joint, required double angle}) {
    if (joint == 'knee') {
      return angle > _baseline![joint]!
          ? 'Next rep: go slightly lower'
          : 'Next rep: do not go as deep';
    }
    return '$joint angle changed from calibration';
  }

  void reset() {
    _calibrationSamples.clear();
    _deviationCounts.clear();
    _baseline = null;
    _repNumber = 0;
  }

  bool _hasEveryTrackedJoint(Map<String, double> angles) =>
      thresholds.joints.keys.every((joint) => angles[joint]?.isFinite ?? false);

  String? _largestAbsoluteFailure(Map<String, double> angles) {
    String? result;
    var largestDistance = 0.0;
    for (final entry in thresholds.joints.entries) {
      final value = angles[entry.key]!;
      final distance = value < entry.value.minimum
          ? entry.value.minimum - value
          : value > entry.value.maximum
          ? value - entry.value.maximum
          : 0.0;
      if (distance > largestDistance) {
        largestDistance = distance;
        result = entry.key;
      }
    }
    return result;
  }

  double _median(Iterable<double> values) {
    final sorted = values.toList()..sort();
    final middle = sorted.length ~/ 2;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}
