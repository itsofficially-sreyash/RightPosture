import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:right_posture/pose_landmark_mapper.dart';
import 'package:right_posture/domain/joint_angle.dart';

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

  test('squat placement requires confident full side away from edges', () {
    final ready = evaluateSquatPlacement(
      mappedLeftSide(),
      imageWidth: 100,
      imageHeight: 100,
    );
    final nearEdge = evaluateSquatPlacement(
      mappedLeftSide(shoulderX: 1),
      imageWidth: 100,
      imageHeight: 100,
    );
    final missing = evaluateSquatPlacement(
      MappedPose(const {}),
      imageWidth: 100,
      imageHeight: 100,
    );

    expect(ready.status, PlacementStatus.ready);
    expect(nearEdge.status, PlacementStatus.nearEdge);
    expect(missing.status, PlacementStatus.missingLandmarks);
  });

  test('maps bilateral elbow angles for bicep curl', () {
    final result = mapPoses([poseWithArms()]);

    expect(result.bicepCurlSample, isNotNull);
    expect(result.bicepCurlSample!.leftElbowAngle, closeTo(90, 1e-9));
    expect(result.bicepCurlSample!.rightElbowAngle, closeTo(90, 1e-9));
  });

  test('curl placement requires both complete arms', () {
    final ready = evaluateBicepCurlPlacement(
      MappedPose({
        for (final joint in const {
          BodyJoint.leftShoulder,
          BodyJoint.rightShoulder,
          BodyJoint.leftElbow,
          BodyJoint.rightElbow,
          BodyJoint.leftWrist,
          BodyJoint.rightWrist,
          BodyJoint.leftHip,
          BodyJoint.rightHip,
        })
          joint: const LandmarkSample(point: Point2(50, 50), confidence: 0.9),
      }),
      imageWidth: 100,
      imageHeight: 100,
    );

    expect(ready.status, PlacementStatus.ready);
    expect(
      evaluateBicepCurlPlacement(
        MappedPose(const {}),
        imageWidth: 100,
        imageHeight: 100,
      ).status,
      PlacementStatus.missingLandmarks,
    );
  });
}

MappedPose mappedLeftSide({double shoulderX = 50}) => MappedPose({
  BodyJoint.leftShoulder: LandmarkSample(
    point: Point2(shoulderX, 20),
    confidence: 0.9,
  ),
  BodyJoint.leftHip: const LandmarkSample(
    point: Point2(50, 45),
    confidence: 0.9,
  ),
  BodyJoint.leftKnee: const LandmarkSample(
    point: Point2(50, 65),
    confidence: 0.9,
  ),
  BodyJoint.leftAnkle: const LandmarkSample(
    point: Point2(50, 85),
    confidence: 0.9,
  ),
});

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

Pose poseWithArms() => Pose(
  landmarks: {
    PoseLandmarkType.leftShoulder: landmark(
      PoseLandmarkType.leftShoulder,
      0,
      1,
      0.9,
    ),
    PoseLandmarkType.leftElbow: landmark(PoseLandmarkType.leftElbow, 0, 0, 0.9),
    PoseLandmarkType.leftWrist: landmark(PoseLandmarkType.leftWrist, 1, 0, 0.9),
    PoseLandmarkType.rightShoulder: landmark(
      PoseLandmarkType.rightShoulder,
      2,
      1,
      0.9,
    ),
    PoseLandmarkType.rightElbow: landmark(
      PoseLandmarkType.rightElbow,
      2,
      0,
      0.9,
    ),
    PoseLandmarkType.rightWrist: landmark(
      PoseLandmarkType.rightWrist,
      3,
      0,
      0.9,
    ),
    PoseLandmarkType.leftHip: landmark(PoseLandmarkType.leftHip, 0, 3, 0.9),
    PoseLandmarkType.rightHip: landmark(PoseLandmarkType.rightHip, 2, 3, 0.9),
  },
);

PoseLandmark landmark(
  PoseLandmarkType type,
  double x,
  double y,
  double confidence,
) {
  return PoseLandmark(type: type, x: x, y: y, z: 0, likelihood: confidence);
}
