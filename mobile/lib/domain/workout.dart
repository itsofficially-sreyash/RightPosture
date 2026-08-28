import 'exercise.dart';
import 'models.dart';

class CompletedSet {
  CompletedSet({
    required this.setNumber,
    required this.exercise,
    required this.completedAt,
    required List<Rep> reps,
    required this.summary,
  }) : reps = List.unmodifiable(reps);

  final int setNumber;
  final ExerciseId exercise;
  final DateTime completedAt;
  final List<Rep> reps;
  final SessionSummary summary;
}

class WorkoutState {
  WorkoutState({
    List<CompletedSet> completedSets = const [],
    this.isFinished = false,
  }) : completedSets = List.unmodifiable(completedSets);

  final List<CompletedSet> completedSets;
  final bool isFinished;
}
