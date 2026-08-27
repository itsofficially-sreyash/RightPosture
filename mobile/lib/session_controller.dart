import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/models.dart';
import 'domain/angle_smoother.dart';
import 'domain/rep_evaluator.dart';
import 'domain/session_summary.dart';
import 'domain/squat_rep_detector.dart';
import 'pose_landmark_mapper.dart';

enum SessionPhase { idle, tracking, complete }

class SessionState {
  SessionState({
    required this.phase,
    required this.selectedExercise,
    List<Rep> reps = const [],
    Map<String, double>? baseline,
    this.latestFeedback,
    this.summary,
    this.error,
    this.coaching,
  }) : reps = List.unmodifiable(reps),
       baseline = baseline == null ? null : Map.unmodifiable(baseline);

  factory SessionState.idle() =>
      SessionState(phase: SessionPhase.idle, selectedExercise: 'squat');

  final SessionPhase phase;
  final String selectedExercise;
  final List<Rep> reps;
  final Map<String, double>? baseline;
  final Rep? latestFeedback;
  final SessionSummary? summary;
  final String? error;
  final SquatCoaching? coaching;
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  late SquatRepDetector _repDetector;
  late RepEvaluator _evaluator;
  late AngleSmoother _kneeAngleSmoother;
  String? _trackedSide;

  @override
  SessionState build() {
    _resetEngines();
    return SessionState.idle();
  }

  void startSession() {
    _resetEngines();
    state = SessionState(
      phase: SessionPhase.tracking,
      selectedExercise: 'squat',
    );
  }

  void acceptPoseSample(SquatFrameSample sample) {
    if (state.phase != SessionPhase.tracking || state.error != null) return;
    final confidenceOk = sample.confidence >= 0.6;
    if (!confidenceOk) {
      trackingInterrupted();
      return;
    }
    _trackedSide ??= sample.side;
    if (sample.side != _trackedSide) return;
    final smoothedAngle = _kneeAngleSmoother.add(sample.kneeAngle);
    if (smoothedAngle == null) return;
    final bottomAngle = _repDetector.addKneeAngle(
      smoothedAngle,
      confidenceOk: confidenceOk,
    );
    final coaching = _repDetector.coachingFor(smoothedAngle);
    if (bottomAngle == null) {
      if (coaching == state.coaching) return;
      state = SessionState(
        phase: state.phase,
        selectedExercise: state.selectedExercise,
        reps: state.reps,
        baseline: state.baseline,
        latestFeedback: state.latestFeedback,
        coaching: coaching,
      );
      return;
    }
    final rep = _evaluator.evaluate({'knee': bottomAngle}, confidenceOk: true);
    if (rep == null) return;
    _trackedSide = null;
    _kneeAngleSmoother.reset();
    state = SessionState(
      phase: SessionPhase.tracking,
      selectedExercise: state.selectedExercise,
      reps: [...state.reps, rep],
      baseline: _evaluator.baseline,
      latestFeedback: rep,
      coaching: coaching,
    );
  }

  void endSession() {
    if (state.phase != SessionPhase.tracking) return;
    state = SessionState(
      phase: SessionPhase.complete,
      selectedExercise: state.selectedExercise,
      reps: state.reps,
      baseline: state.baseline,
      latestFeedback: state.latestFeedback,
      coaching: state.coaching,
      summary: summarizeSession(state.reps),
    );
  }

  void reportFailure(String message) {
    if (state.phase != SessionPhase.tracking) return;
    _resetTrackingInput();
    state = SessionState(
      phase: state.phase,
      selectedExercise: state.selectedExercise,
      reps: state.reps,
      baseline: state.baseline,
      latestFeedback: state.latestFeedback,
      coaching: state.coaching,
      error: message,
    );
  }

  void retry() {
    if (state.error == null) return;
    state = SessionState(
      phase: state.phase,
      selectedExercise: state.selectedExercise,
      reps: state.reps,
      baseline: state.baseline,
      latestFeedback: state.latestFeedback,
      coaching: state.coaching,
    );
  }

  void reset() {
    _resetEngines();
    state = SessionState.idle();
  }

  void trackingInterrupted() {
    if (state.phase != SessionPhase.tracking) return;
    _resetTrackingInput();
    if (state.coaching == null) return;
    state = SessionState(
      phase: state.phase,
      selectedExercise: state.selectedExercise,
      reps: state.reps,
      baseline: state.baseline,
      latestFeedback: state.latestFeedback,
    );
  }

  void _resetEngines() {
    _repDetector = SquatRepDetector();
    _evaluator = RepEvaluator(squatExerciseThresholds());
    _kneeAngleSmoother = AngleSmoother();
    _trackedSide = null;
  }

  void _resetTrackingInput() {
    _repDetector.reset();
    _kneeAngleSmoother.reset();
    _trackedSide = null;
  }
}

ExerciseThresholds squatExerciseThresholds() => ExerciseThresholds(
  joints: const {
    'knee': JointThreshold(minimum: 70, maximum: 140, deviationThreshold: 20),
  },
  persistenceCount: 3,
);
