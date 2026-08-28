import 'exercise.dart';
import 'bicep_curl_rep_detector.dart';
import 'lateral_raise_rep_detector.dart';
import 'squat_rep_detector.dart';
import 'shoulder_press_rep_detector.dart';

class ExerciseRegistry {
  const ExerciseRegistry();

  ExerciseProfile profileFor(ExerciseId id) => switch (id) {
    ExerciseId.squat => squatExerciseProfile,
    ExerciseId.bicepCurl => bicepCurlExerciseProfile,
    ExerciseId.lateralRaise => lateralRaiseExerciseProfile,
    ExerciseId.shoulderPress => shoulderPressExerciseProfile,
    _ => throw UnsupportedError('${id.name} is not implemented'),
  };

  RepDetector detectorFor(ExerciseId id) => switch (id) {
    ExerciseId.squat => SquatRepDetector(),
    ExerciseId.bicepCurl => BicepCurlRepDetector(),
    ExerciseId.lateralRaise => LateralRaiseRepDetector(),
    ExerciseId.shoulderPress => ShoulderPressRepDetector(),
    _ => throw UnsupportedError('${id.name} is not implemented'),
  };
}
