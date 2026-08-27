import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'pose_landmark_mapper.dart';

Offset translatePosePoint({
  required Offset point,
  required Size canvasSize,
  required Size imageSize,
  required int rotationDegrees,
  required bool mirrored,
}) {
  final rotated = rotationDegrees == 90 || rotationDegrees == 270;
  final sourceWidth = rotated ? imageSize.height : imageSize.width;
  final sourceHeight = rotated ? imageSize.width : imageSize.height;
  final mirror = rotationDegrees == 270 || (!rotated && mirrored);
  final sourceX = mirror ? sourceWidth - point.dx : point.dx;
  final scale = math.max(
    canvasSize.width / sourceWidth,
    canvasSize.height / sourceHeight,
  );
  final offsetX = (canvasSize.width - sourceWidth * scale) / 2;
  final offsetY = (canvasSize.height - sourceHeight * scale) / 2;
  return Offset(sourceX * scale + offsetX, point.dy * scale + offsetY);
}

class PosePainter extends CustomPainter {
  PosePainter({
    required this.poses,
    required this.imageSize,
    required this.rotationDegrees,
    required this.mirrored,
  });

  final List<MappedPose> poses;
  final Size imageSize;
  final int rotationDegrees;
  final bool mirrored;

  static const _connections = <(BodyJoint, BodyJoint)>[
    (BodyJoint.leftShoulder, BodyJoint.rightShoulder),
    (BodyJoint.leftShoulder, BodyJoint.leftElbow),
    (BodyJoint.leftElbow, BodyJoint.leftWrist),
    (BodyJoint.rightShoulder, BodyJoint.rightElbow),
    (BodyJoint.rightElbow, BodyJoint.rightWrist),
    (BodyJoint.leftShoulder, BodyJoint.leftHip),
    (BodyJoint.rightShoulder, BodyJoint.rightHip),
    (BodyJoint.leftHip, BodyJoint.rightHip),
    (BodyJoint.leftHip, BodyJoint.leftKnee),
    (BodyJoint.leftKnee, BodyJoint.leftAnkle),
    (BodyJoint.rightHip, BodyJoint.rightKnee),
    (BodyJoint.rightKnee, BodyJoint.rightAnkle),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    Offset point(LandmarkSample landmark) => translatePosePoint(
      point: Offset(landmark.point.x, landmark.point.y),
      canvasSize: size,
      imageSize: imageSize,
      rotationDegrees: rotationDegrees,
      mirrored: mirrored,
    );
    final paint = Paint()
      ..color = const Color(0xFFD6FF5A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (final pose in poses) {
      for (final (startType, endType) in _connections) {
        final start = pose.landmarks[startType];
        final end = pose.landmarks[endType];
        if (start != null && end != null) {
          canvas.drawLine(point(start), point(end), paint);
        }
      }
      for (final landmark in pose.landmarks.values) {
        canvas.drawCircle(point(landmark), 4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(PosePainter oldDelegate) =>
      oldDelegate.poses != poses ||
      oldDelegate.imageSize != imageSize ||
      oldDelegate.rotationDegrees != rotationDegrees ||
      oldDelegate.mirrored != mirrored;
}
