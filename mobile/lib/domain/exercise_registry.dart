import 'exercise.dart';
import 'squat_rep_detector.dart';

class ExerciseRegistry {
  const ExerciseRegistry();

  ExerciseProfile profileFor(ExerciseId id) => switch (id) {
    ExerciseId.squat => squatExerciseProfile,
    _ => throw UnsupportedError('${id.name} is not implemented'),
  };

  RepDetector detectorFor(ExerciseId id) => switch (id) {
    ExerciseId.squat => SquatRepDetector(),
    _ => throw UnsupportedError('${id.name} is not implemented'),
  };
}
