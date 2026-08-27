import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  PosePainter({required this.poses, required this.imageSize});

  final List<Pose> poses;
  final Size imageSize;

  static const _connections = <(PoseLandmarkType, PoseLandmarkType)>[
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
    (PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
    (PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
    (PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
    (PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),
    (PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
    (PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
    (PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
    (PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / imageSize.width;
    final displayedHeight = imageSize.height * scale;
    final offsetY = (size.height - displayedHeight) / 2;
    Offset point(PoseLandmark landmark) =>
        Offset(landmark.x * scale, landmark.y * scale + offsetY);
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
      oldDelegate.poses != poses || oldDelegate.imageSize != imageSize;
}
