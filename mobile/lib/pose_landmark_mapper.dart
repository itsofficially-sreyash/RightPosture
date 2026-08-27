import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
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

class PoseMappingResult {
  PoseMappingResult({
    required List<MappedPose> poses,
    this.squatSample,
    this.squatCandidate,
  }) : poses = List.unmodifiable(poses);

  final List<MappedPose> poses;
  final SquatFrameSample? squatSample;
  final SquatFrameSample? squatCandidate;
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
  return PoseMappingResult(
    poses: mapped,
    squatSample: candidate != null && candidate.confidence >= minimumConfidence
        ? candidate
        : null,
    squatCandidate: candidate,
  );
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
