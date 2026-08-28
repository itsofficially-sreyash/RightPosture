import 'exercise.dart';
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

  Rep? evaluate(
    Map<String, double> angles, {
    required bool confidenceOk,
    RepMetrics? metrics,
  }) {
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
        metrics: metrics,
      );
    }

    final absoluteFailure = _largestAbsoluteFailure(angles);
    if (absoluteFailure != null) {
      _deviationCounts.clear();
      final value = angles[absoluteFailure]!;
      final threshold = thresholds.joints[absoluteFailure]!;
      return Rep(
        number: _repNumber,
        angles: Map.unmodifiable(angles),
        status: RepStatus.degraded,
        metrics: metrics,
        issues: [
          RepIssue(
            exercise: ExerciseId.squat,
            metric: _metricForJoint(absoluteFailure),
            direction: value < threshold.minimum
                ? IssueDirection.aboveRange
                : IssueDirection.belowRange,
            measuredValue: value,
            baselineValue: _baseline?[absoluteFailure],
            normalizedSeverity:
                (value < threshold.minimum
                    ? threshold.minimum - value
                    : value - threshold.maximum) /
                threshold.deviationThreshold,
          ),
        ],
      );
    }

    String? largestDeviationJoint;
    var largestDeviationRatio = 0.0;
    final issues = <RepIssue>[];
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
        issues.add(
          RepIssue(
            exercise: ExerciseId.squat,
            metric: _metricForJoint(joint),
            direction: angles[joint]! > _baseline![joint]!
                ? IssueDirection.increased
                : IssueDirection.decreased,
            measuredValue: angles[joint]!,
            baselineValue: _baseline![joint],
            normalizedSeverity: ratio,
          ),
        );
      } else {
        _deviationCounts[joint] = 0;
      }
    }

    if (largestDeviationJoint == null) {
      return Rep(
        number: _repNumber,
        angles: Map.unmodifiable(angles),
        status: RepStatus.good,
        metrics: metrics,
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
      issues: issues,
      metrics: metrics,
    );
  }

  MovementMetric _metricForJoint(String joint) => switch (joint) {
    'knee' => MovementMetric.kneeAngle,
    _ => throw StateError('Unsupported squat metric: $joint'),
  };

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
