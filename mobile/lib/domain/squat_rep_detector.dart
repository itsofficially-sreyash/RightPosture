enum SquatMovementPhase { waitingForStanding, waitingForBottom, returning }

enum SquatCoaching { standTall, ready, goLower, depthGood, standUp, tooDeep }

class SquatRepDetector {
  SquatRepDetector({
    this.bottomMaximumAngle = 110,
    this.standingMinimumAngle = 160,
  }) : assert(bottomMaximumAngle < standingMinimumAngle);

  final double bottomMaximumAngle;
  final double standingMinimumAngle;
  SquatMovementPhase _phase = SquatMovementPhase.waitingForStanding;
  double? _bottomAngle;

  SquatMovementPhase get phase => _phase;

  double? addKneeAngle(double angle, {required bool confidenceOk}) {
    if (!confidenceOk || !angle.isFinite) return null;
    return switch (_phase) {
      SquatMovementPhase.waitingForStanding => _armFromStanding(angle),
      SquatMovementPhase.waitingForBottom => _detectBottom(angle),
      SquatMovementPhase.returning => _detectReturn(angle),
    };
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
            : SquatCoaching.standUp,
    };
  }

  double? _armFromStanding(double angle) {
    if (angle >= standingMinimumAngle) {
      _phase = SquatMovementPhase.waitingForBottom;
    }
    return null;
  }

  double? _detectBottom(double angle) {
    if (angle <= bottomMaximumAngle) {
      _bottomAngle = angle;
      _phase = SquatMovementPhase.returning;
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
    _phase = SquatMovementPhase.waitingForBottom;
    return result;
  }

  void reset() {
    _phase = SquatMovementPhase.waitingForStanding;
    _bottomAngle = null;
  }
}
