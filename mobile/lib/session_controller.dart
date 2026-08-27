import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/models.dart';
import 'domain/angle_smoother.dart';
import 'domain/exercise.dart';
import 'domain/exercise_registry.dart';
import 'domain/rep_evaluator.dart';
import 'domain/session_summary.dart';
import 'domain/squat_rep_detector.dart';
import 'pose_landmark_mapper.dart';

enum SessionPhase { idle, preparing, countdown, tracking, complete }

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
    this.placementStable = false,
    this.placementGuidance,
    this.countdownValue,
  }) : reps = List.unmodifiable(reps),
       baseline = baseline == null ? null : Map.unmodifiable(baseline);

  factory SessionState.idle() => SessionState(
    phase: SessionPhase.idle,
    selectedExercise: ExerciseId.squat,
  );

  final SessionPhase phase;
  final ExerciseId selectedExercise;
  final List<Rep> reps;
  final Map<String, double>? baseline;
  final Rep? latestFeedback;
  final SessionSummary? summary;
  final String? error;
  final SquatCoaching? coaching;
  final bool placementStable;
  final String? placementGuidance;
  final int? countdownValue;
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  late SquatRepDetector _repDetector;
  late RepEvaluator _evaluator;
  late AngleSmoother _kneeAngleSmoother;
  final ExerciseRegistry _registry = const ExerciseRegistry();
  String? _trackedSide;
  Timer? _countdownTimer;
  int _stablePlacementFrames = 0;

  @override
  SessionState build() {
    ref.onDispose(_cancelCountdown);
    _resetEngines();
    return SessionState.idle();
  }

  void startSession() => prepareSession();

  void prepareSession() {
    _cancelCountdown();
    _resetEngines();
    _stablePlacementFrames = 0;
    state = SessionState(
      phase: SessionPhase.preparing,
      selectedExercise: ExerciseId.squat,
      placementGuidance: squatExerciseProfile.setupInstruction,
    );
  }

  void acceptPreparationResult(PlacementResult result) {
    if (state.phase != SessionPhase.preparing &&
        state.phase != SessionPhase.countdown) {
      return;
    }
    if (!result.isReady) {
      _stablePlacementFrames = 0;
      _cancelCountdown();
      state = SessionState(
        phase: SessionPhase.preparing,
        selectedExercise: state.selectedExercise,
        placementGuidance: result.message,
      );
      return;
    }
    if (state.phase == SessionPhase.countdown) return;
    _stablePlacementFrames++;
    final stable = _stablePlacementFrames >= 3;
    if (state.placementStable == stable &&
        state.placementGuidance == result.message) {
      return;
    }
    state = SessionState(
      phase: SessionPhase.preparing,
      selectedExercise: state.selectedExercise,
      placementStable: stable,
      placementGuidance: result.message,
    );
  }

  void startCountdown() {
    if (state.phase != SessionPhase.preparing || !state.placementStable) return;
    _cancelCountdown();
    state = SessionState(
      phase: SessionPhase.countdown,
      selectedExercise: state.selectedExercise,
      placementStable: true,
      placementGuidance: state.placementGuidance,
      countdownValue: 3,
    );
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => advanceCountdown(),
    );
  }

  void advanceCountdown() {
    if (state.phase != SessionPhase.countdown) return;
    final value = state.countdownValue ?? 3;
    if (value <= 1) {
      startTracking();
      return;
    }
    state = SessionState(
      phase: SessionPhase.countdown,
      selectedExercise: state.selectedExercise,
      placementStable: true,
      placementGuidance: state.placementGuidance,
      countdownValue: value - 1,
    );
  }

  void startTracking() {
    _cancelCountdown();
    _resetEngines();
    state = SessionState(
      phase: SessionPhase.tracking,
      selectedExercise: state.selectedExercise,
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
    final completion = _repDetector.addFrame(
      MovementFrame(
        timestamp: DateTime.now(),
        values: {MovementMetric.kneeAngle: smoothedAngle},
        confidence: {MovementMetric.kneeAngle: sample.confidence},
        trackedSide: switch (sample.side) {
          'left' => TrackedSide.left,
          'right' => TrackedSide.right,
          _ => TrackedSide.unknown,
        },
      ),
    );
    final coaching = _repDetector.coachingFor(smoothedAngle);
    if (completion == null) {
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
    final rep = _evaluator.evaluate({
      'knee': completion.minimumValues[MovementMetric.kneeAngle]!,
    }, confidenceOk: true);
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
      coaching: state.coaching,
    );
  }

  void reset() {
    _cancelCountdown();
    _resetEngines();
    state = SessionState.idle();
  }

  void trackingInterrupted() {
    if (state.phase == SessionPhase.preparing ||
        state.phase == SessionPhase.countdown) {
      acceptPreparationResult(
        const PlacementResult(
          PlacementStatus.missingLandmarks,
          'Position lost — step into frame',
        ),
      );
      return;
    }
    if (state.phase != SessionPhase.tracking) return;
    _resetTrackingInput();
    state = SessionState(
      phase: state.phase,
      selectedExercise: state.selectedExercise,
      reps: state.reps,
      baseline: state.baseline,
    );
  }

  void _resetEngines() {
    _repDetector = _registry.detectorFor(ExerciseId.squat) as SquatRepDetector;
    _evaluator = RepEvaluator(squatExerciseThresholds());
    _kneeAngleSmoother = AngleSmoother();
    _trackedSide = null;
  }

  void _resetTrackingInput() {
    _repDetector.reset();
    _kneeAngleSmoother.reset();
    _trackedSide = null;
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }
}

ExerciseThresholds squatExerciseThresholds() => ExerciseThresholds(
  joints: const {
    'knee': JointThreshold(minimum: 70, maximum: 140, deviationThreshold: 20),
  },
  persistenceCount: 3,
);
