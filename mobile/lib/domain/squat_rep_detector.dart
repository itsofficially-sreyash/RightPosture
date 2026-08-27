class SquatRepDetector {
  SquatRepDetector({
    this.bottomMaximumAngle = 110,
    this.standingMinimumAngle = 160,
  }) : assert(bottomMaximumAngle < standingMinimumAngle);

  final double bottomMaximumAngle;
  final double standingMinimumAngle;
  _SquatPhase _phase = _SquatPhase.waitingForStanding;
  double? _bottomAngle;

  double? addKneeAngle(double angle, {required bool confidenceOk}) {
    if (!confidenceOk || !angle.isFinite) return null;
    return switch (_phase) {
      _SquatPhase.waitingForStanding => _armFromStanding(angle),
      _SquatPhase.waitingForBottom => _detectBottom(angle),
      _SquatPhase.waitingForReturn => _detectReturn(angle),
    };
  }

  double? _armFromStanding(double angle) {
    if (angle >= standingMinimumAngle) _phase = _SquatPhase.waitingForBottom;
    return null;
  }

  double? _detectBottom(double angle) {
    if (angle <= bottomMaximumAngle) {
      _bottomAngle = angle;
      _phase = _SquatPhase.waitingForReturn;
    }
    return null;
  }

  double? _detectReturn(double angle) {
    if (angle < standingMinimumAngle) {
      if (angle < (_bottomAngle ?? double.infinity)) _bottomAngle = angle;
      return null;
    }
    final result = _bottomAngle;
    _bottomAngle = null;
    _phase = _SquatPhase.waitingForBottom;
    return result;
  }

  void reset() {
    _phase = _SquatPhase.waitingForStanding;
    _bottomAngle = null;
  }
}

enum _SquatPhase { waitingForStanding, waitingForBottom, waitingForReturn }
