import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:right_posture/pose_landmark_mapper.dart';

void main() {
  test('returns no pose sample when no person is detected', () {
    final result = mapPoses(const []);
    expect(result.poses, isEmpty);
    expect(result.squatSample, isNull);
  });

  test('maps overlay joints and selects higher-confidence side', () {
    final result = mapPoses([
      poseWithLegs(leftConfidence: 0.7, rightConfidence: 0.9),
    ]);
    expect(result.poses.single.landmarks, contains(BodyJoint.leftKnee));
    expect(result.poses.single.landmarks, contains(BodyJoint.rightKnee));
    expect(result.squatSample!.side, 'right');
    expect(result.squatSample!.kneeAngle, closeTo(90, 1e-9));
    expect(result.squatSample!.confidence, 0.9);
  });

  test('uses one valid side when the other is below confidence threshold', () {
    final result = mapPoses([
      poseWithLegs(leftConfidence: 0.2, rightConfidence: 0.8),
    ]);
    expect(result.squatSample!.side, 'right');
  });

  test('metric confidence uses weakest required landmark', () {
    final result = mapPoses([
      poseWithLegs(
        leftConfidence: 0.9,
        leftKneeConfidence: 0.65,
        rightConfidence: 0.2,
      ),
    ]);

    expect(result.squatSample!.confidence, 0.65);
  });

  test('reports low confidence when neither side is reliable', () {
    final result = mapPoses([
      poseWithLegs(leftConfidence: 0.2, rightConfidence: 0.3),
    ]);
    expect(result.poses, isNotEmpty);
    expect(result.squatSample, isNull);
    expect(result.squatCandidate!.confidence, 0.3);
  });

  test('uses first pose deterministically for squat sample', () {
    final result = mapPoses([
      poseWithLegs(leftConfidence: 0.9, rightConfidence: 0.7),
      poseWithLegs(leftConfidence: 0.7, rightConfidence: 0.9),
    ]);
    expect(result.squatSample!.side, 'left');
    expect(result.poses, hasLength(2));
  });
}

Pose poseWithLegs({
  required double leftConfidence,
  required double rightConfidence,
  double? leftKneeConfidence,
}) {
  return Pose(
    landmarks: {
      PoseLandmarkType.leftHip: landmark(
        PoseLandmarkType.leftHip,
        0,
        1,
        leftConfidence,
      ),
      PoseLandmarkType.leftKnee: landmark(
        PoseLandmarkType.leftKnee,
        0,
        0,
        leftKneeConfidence ?? leftConfidence,
      ),
      PoseLandmarkType.leftAnkle: landmark(
        PoseLandmarkType.leftAnkle,
        1,
        0,
        leftConfidence,
      ),
      PoseLandmarkType.rightHip: landmark(
        PoseLandmarkType.rightHip,
        2,
        1,
        rightConfidence,
      ),
      PoseLandmarkType.rightKnee: landmark(
        PoseLandmarkType.rightKnee,
        2,
        0,
        rightConfidence,
      ),
      PoseLandmarkType.rightAnkle: landmark(
        PoseLandmarkType.rightAnkle,
        3,
        0,
        rightConfidence,
      ),
    },
  );
}

PoseLandmark landmark(
  PoseLandmarkType type,
  double x,
  double y,
  double confidence,
) {
  return PoseLandmark(type: type, x: x, y: y, z: 0, likelihood: confidence);
}
