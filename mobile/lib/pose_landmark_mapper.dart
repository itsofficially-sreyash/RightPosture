import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math' as math;
import 'domain/joint_angle.dart';
import 'domain/exercise.dart';

export 'domain/exercise.dart' show BodyJoint;

enum PlacementStatus { ready, missingLandmarks, nearEdge }

class PlacementResult {
  const PlacementResult(this.status, this.message);

  final PlacementStatus status;
  final String message;

  bool get isReady => status == PlacementStatus.ready;
}

class LandmarkSample {
  const LandmarkSample({required this.point, required this.confidence});

  final Point2 point;
  final double confidence;
}

class MappedPose {
  MappedPose(Map<BodyJoint, LandmarkSample> landmarks)
    : landmarks = Map.unmodifiable(landmarks);

  final Map<BodyJoint, LandmarkSample> landmarks;
}

class SquatFrameSample {
  const SquatFrameSample({
    required this.kneeAngle,
    required this.side,
    required this.confidence,
  });

  final double kneeAngle;
  final String side;
  final double confidence;
}

class BicepCurlFrameSample {
  const BicepCurlFrameSample({
    required this.leftElbowAngle,
    required this.rightElbowAngle,
    required this.leftConfidence,
    required this.rightConfidence,
    required this.torsoVerticalPosition,
    required this.torsoConfidence,
  });

  final double leftElbowAngle;
  final double rightElbowAngle;
  final double leftConfidence;
  final double rightConfidence;
  final double torsoVerticalPosition;
  final double torsoConfidence;
}

class LateralRaiseFrameSample {
  const LateralRaiseFrameSample({
    required this.leftArmElevation,
    required this.rightArmElevation,
    required this.leftElbowAngle,
    required this.rightElbowAngle,
    required this.torsoLean,
    required this.leftConfidence,
    required this.rightConfidence,
    required this.torsoConfidence,
  });

  final double leftArmElevation;
  final double rightArmElevation;
  final double leftElbowAngle;
  final double rightElbowAngle;
  final double torsoLean;
  final double leftConfidence;
  final double rightConfidence;
  final double torsoConfidence;
}

class PoseMappingResult {
  PoseMappingResult({
    required List<MappedPose> poses,
    this.squatSample,
    this.squatCandidate,
    this.bicepCurlSample,
    this.lateralRaiseSample,
  }) : poses = List.unmodifiable(poses);

  final List<MappedPose> poses;
  final SquatFrameSample? squatSample;
  final SquatFrameSample? squatCandidate;
  final BicepCurlFrameSample? bicepCurlSample;
  final LateralRaiseFrameSample? lateralRaiseSample;
}

PlacementResult evaluateBicepCurlPlacement(
  MappedPose? pose, {
  required double imageWidth,
  required double imageHeight,
  double minimumConfidence = 0.6,
  double edgeMarginRatio = 0.05,
}) {
  if (pose == null || imageWidth <= 0 || imageHeight <= 0) {
    return const PlacementResult(
      PlacementStatus.missingLandmarks,
      'Step into frame',
    );
  }
  const joints = {
    BodyJoint.leftShoulder,
    BodyJoint.rightShoulder,
    BodyJoint.leftElbow,
    BodyJoint.rightElbow,
    BodyJoint.leftWrist,
    BodyJoint.rightWrist,
    BodyJoint.leftHip,
    BodyJoint.rightHip,
  };
  if (!joints.every(
    (joint) => (pose.landmarks[joint]?.confidence ?? 0) >= minimumConfidence,
  )) {
    return const PlacementResult(
      PlacementStatus.missingLandmarks,
      'Show both shoulders, elbows, wrists, and hips',
    );
  }
  final xMargin = imageWidth * edgeMarginRatio;
  final yMargin = imageHeight * edgeMarginRatio;
  if (joints.any((joint) {
    final point = pose.landmarks[joint]!.point;
    return point.x < xMargin ||
        point.x > imageWidth - xMargin ||
        point.y < yMargin ||
        point.y > imageHeight - yMargin;
  })) {
    return const PlacementResult(PlacementStatus.nearEdge, 'Move farther back');
  }
  return const PlacementResult(PlacementStatus.ready, 'Position ready');
}

PlacementResult evaluateSquatPlacement(
  MappedPose? pose, {
  required double imageWidth,
  required double imageHeight,
  double minimumConfidence = 0.6,
  double edgeMarginRatio = 0.05,
}) {
  if (pose == null || imageWidth <= 0 || imageHeight <= 0) {
    return const PlacementResult(
      PlacementStatus.missingLandmarks,
      'Step into frame',
    );
  }
  const left = [
    BodyJoint.leftShoulder,
    BodyJoint.leftHip,
    BodyJoint.leftKnee,
    BodyJoint.leftAnkle,
  ];
  const right = [
    BodyJoint.rightShoulder,
    BodyJoint.rightHip,
    BodyJoint.rightKnee,
    BodyJoint.rightAnkle,
  ];
  final joints = [left, right].where(
    (side) => side.every(
      (joint) => (pose.landmarks[joint]?.confidence ?? 0) >= minimumConfidence,
    ),
  );
  if (joints.isEmpty) {
    return const PlacementResult(
      PlacementStatus.missingLandmarks,
      'Move back — show shoulders, hips, knees, and ankles',
    );
  }
  final xMargin = imageWidth * edgeMarginRatio;
  final yMargin = imageHeight * edgeMarginRatio;
  final nearEdge = joints.first.any((joint) {
    final point = pose.landmarks[joint]!.point;
    return point.x < xMargin ||
        point.x > imageWidth - xMargin ||
        point.y < yMargin ||
        point.y > imageHeight - yMargin;
  });
  if (nearEdge) {
    return const PlacementResult(PlacementStatus.nearEdge, 'Move farther back');
  }
  return const PlacementResult(PlacementStatus.ready, 'Position ready');
}

PoseMappingResult mapPoses(List<Pose> poses, {double minimumConfidence = 0.6}) {
  if (poses.isEmpty) return PoseMappingResult(poses: const []);
  final mapped = poses.map(_mapOverlayLandmarks).toList(growable: false);
  final candidate = _bestSquatSample(poses.first);
  final curl = _bicepCurlSample(poses.first, minimumConfidence);
  final lateralRaise = _lateralRaiseSample(poses.first, minimumConfidence);
  return PoseMappingResult(
    poses: mapped,
    squatSample: candidate != null && candidate.confidence >= minimumConfidence
        ? candidate
        : null,
    squatCandidate: candidate,
    bicepCurlSample: curl,
    lateralRaiseSample: lateralRaise,
  );
}

LateralRaiseFrameSample? _lateralRaiseSample(
  Pose pose,
  double minimumConfidence,
) {
  final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
  final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
  final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
  final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
  final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
  final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
  final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
  final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
  if ([
    leftShoulder,
    rightShoulder,
    leftElbow,
    rightElbow,
    leftWrist,
    rightWrist,
    leftHip,
    rightHip,
  ].any((landmark) => landmark == null)) {
    return null;
  }
  final leftConfidence = [
    leftShoulder!.likelihood,
    leftElbow!.likelihood,
    leftWrist!.likelihood,
    leftHip!.likelihood,
  ].reduce((a, b) => a < b ? a : b);
  final rightConfidence = [
    rightShoulder!.likelihood,
    rightElbow!.likelihood,
    rightWrist!.likelihood,
    rightHip!.likelihood,
  ].reduce((a, b) => a < b ? a : b);
  if (leftConfidence < minimumConfidence ||
      rightConfidence < minimumConfidence) {
    return null;
  }
  final leftElevation = jointAngle(
    Point2(leftHip.x, leftHip.y),
    Point2(leftShoulder.x, leftShoulder.y),
    Point2(leftWrist.x, leftWrist.y),
  );
  final rightElevation = jointAngle(
    Point2(rightHip.x, rightHip.y),
    Point2(rightShoulder.x, rightShoulder.y),
    Point2(rightWrist.x, rightWrist.y),
  );
  final leftElbowAngle = jointAngle(
    Point2(leftShoulder.x, leftShoulder.y),
    Point2(leftElbow.x, leftElbow.y),
    Point2(leftWrist.x, leftWrist.y),
  );
  final rightElbowAngle = jointAngle(
    Point2(rightShoulder.x, rightShoulder.y),
    Point2(rightElbow.x, rightElbow.y),
    Point2(rightWrist.x, rightWrist.y),
  );
  if (leftElevation == null ||
      rightElevation == null ||
      leftElbowAngle == null ||
      rightElbowAngle == null) {
    return null;
  }
  final shoulderX = (leftShoulder.x + rightShoulder.x) / 2;
  final shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
  final hipX = (leftHip.x + rightHip.x) / 2;
  final hipY = (leftHip.y + rightHip.y) / 2;
  final torsoLean =
      math.atan2(hipX - shoulderX, hipY - shoulderY) * 180 / math.pi;
  final torsoConfidence = [
    leftShoulder.likelihood,
    rightShoulder.likelihood,
    leftHip.likelihood,
    rightHip.likelihood,
  ].reduce((a, b) => a < b ? a : b);
  return LateralRaiseFrameSample(
    leftArmElevation: leftElevation,
    rightArmElevation: rightElevation,
    leftElbowAngle: leftElbowAngle,
    rightElbowAngle: rightElbowAngle,
    torsoLean: torsoLean,
    leftConfidence: leftConfidence,
    rightConfidence: rightConfidence,
    torsoConfidence: torsoConfidence,
  );
}

BicepCurlFrameSample? _bicepCurlSample(Pose pose, double minimumConfidence) {
  final left = _armSample(
    pose,
    shoulder: PoseLandmarkType.leftShoulder,
    elbow: PoseLandmarkType.leftElbow,
    wrist: PoseLandmarkType.leftWrist,
  );
  final right = _armSample(
    pose,
    shoulder: PoseLandmarkType.rightShoulder,
    elbow: PoseLandmarkType.rightElbow,
    wrist: PoseLandmarkType.rightWrist,
  );
  if (left == null ||
      right == null ||
      left.$2 < minimumConfidence ||
      right.$2 < minimumConfidence) {
    return null;
  }
  final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
  final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
  final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
  final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
  if (leftShoulder == null ||
      rightShoulder == null ||
      leftHip == null ||
      rightHip == null) {
    return null;
  }
  final shoulderCenter = Point2(
    (leftShoulder.x + rightShoulder.x) / 2,
    (leftShoulder.y + rightShoulder.y) / 2,
  );
  final hipCenter = Point2(
    (leftHip.x + rightHip.x) / 2,
    (leftHip.y + rightHip.y) / 2,
  );
  final torsoX = hipCenter.x - shoulderCenter.x;
  final torsoY = hipCenter.y - shoulderCenter.y;
  final torsoLength = math.sqrt(torsoX * torsoX + torsoY * torsoY);
  if (!torsoLength.isFinite || torsoLength == 0) return null;
  final torsoConfidence = [
    leftShoulder.likelihood,
    rightShoulder.likelihood,
    leftHip.likelihood,
    rightHip.likelihood,
  ].reduce((a, b) => a < b ? a : b);
  if (torsoConfidence < minimumConfidence) return null;
  return BicepCurlFrameSample(
    leftElbowAngle: left.$1,
    rightElbowAngle: right.$1,
    leftConfidence: left.$2,
    rightConfidence: right.$2,
    torsoVerticalPosition: shoulderCenter.y / torsoLength,
    torsoConfidence: torsoConfidence,
  );
}

(double, double)? _armSample(
  Pose pose, {
  required PoseLandmarkType shoulder,
  required PoseLandmarkType elbow,
  required PoseLandmarkType wrist,
}) {
  final shoulderPoint = pose.landmarks[shoulder];
  final elbowPoint = pose.landmarks[elbow];
  final wristPoint = pose.landmarks[wrist];
  if (shoulderPoint == null || elbowPoint == null || wristPoint == null) {
    return null;
  }
  final confidence = [
    shoulderPoint.likelihood,
    elbowPoint.likelihood,
    wristPoint.likelihood,
  ].reduce((a, b) => a < b ? a : b);
  final angle = jointAngle(
    Point2(shoulderPoint.x, shoulderPoint.y),
    Point2(elbowPoint.x, elbowPoint.y),
    Point2(wristPoint.x, wristPoint.y),
  );
  return angle == null ? null : (angle, confidence);
}

MappedPose _mapOverlayLandmarks(Pose pose) {
  const types = <BodyJoint, PoseLandmarkType>{
    BodyJoint.leftShoulder: PoseLandmarkType.leftShoulder,
    BodyJoint.rightShoulder: PoseLandmarkType.rightShoulder,
    BodyJoint.leftElbow: PoseLandmarkType.leftElbow,
    BodyJoint.rightElbow: PoseLandmarkType.rightElbow,
    BodyJoint.leftWrist: PoseLandmarkType.leftWrist,
    BodyJoint.rightWrist: PoseLandmarkType.rightWrist,
    BodyJoint.leftHip: PoseLandmarkType.leftHip,
    BodyJoint.rightHip: PoseLandmarkType.rightHip,
    BodyJoint.leftKnee: PoseLandmarkType.leftKnee,
    BodyJoint.rightKnee: PoseLandmarkType.rightKnee,
    BodyJoint.leftAnkle: PoseLandmarkType.leftAnkle,
    BodyJoint.rightAnkle: PoseLandmarkType.rightAnkle,
  };
  return MappedPose({
    for (final entry in types.entries)
      if (pose.landmarks[entry.value] case final landmark?)
        entry.key: LandmarkSample(
          point: Point2(landmark.x, landmark.y),
          confidence: landmark.likelihood,
        ),
  });
}

SquatFrameSample? _bestSquatSample(Pose pose) {
  final left = _sideSample(
    pose,
    hip: PoseLandmarkType.leftHip,
    knee: PoseLandmarkType.leftKnee,
    ankle: PoseLandmarkType.leftAnkle,
    side: 'left',
  );
  final right = _sideSample(
    pose,
    hip: PoseLandmarkType.rightHip,
    knee: PoseLandmarkType.rightKnee,
    ankle: PoseLandmarkType.rightAnkle,
    side: 'right',
  );
  if (left == null) return right;
  if (right == null) return left;
  return left.confidence >= right.confidence ? left : right;
}

SquatFrameSample? _sideSample(
  Pose pose, {
  required PoseLandmarkType hip,
  required PoseLandmarkType knee,
  required PoseLandmarkType ankle,
  required String side,
}) {
  final hipPoint = pose.landmarks[hip];
  final kneePoint = pose.landmarks[knee];
  final anklePoint = pose.landmarks[ankle];
  if (hipPoint == null || kneePoint == null || anklePoint == null) return null;
  final confidence = [
    hipPoint.likelihood,
    kneePoint.likelihood,
    anklePoint.likelihood,
  ].reduce((a, b) => a < b ? a : b);
  if (!confidence.isFinite) return null;
  final angle = jointAngle(
    Point2(hipPoint.x, hipPoint.y),
    Point2(kneePoint.x, kneePoint.y),
    Point2(anklePoint.x, anklePoint.y),
  );
  if (angle == null) return null;
  return SquatFrameSample(kneeAngle: angle, side: side, confidence: confidence);
}
