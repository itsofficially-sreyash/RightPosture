import 'exercise.dart';
import 'bicep_curl_rep_detector.dart';
import 'squat_rep_detector.dart';

class ExerciseRegistry {
  const ExerciseRegistry();

  ExerciseProfile profileFor(ExerciseId id) => switch (id) {
    ExerciseId.squat => squatExerciseProfile,
    ExerciseId.bicepCurl => bicepCurlExerciseProfile,
    _ => throw UnsupportedError('${id.name} is not implemented'),
  };

  RepDetector detectorFor(ExerciseId id) => switch (id) {
    ExerciseId.squat => SquatRepDetector(),
    ExerciseId.bicepCurl => BicepCurlRepDetector(),
    _ => throw UnsupportedError('${id.name} is not implemented'),
  };
}
