import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'domain/joint_angle.dart';
import 'pose_landmark_mapper.dart';

const poseInterpolationDuration = Duration(milliseconds: 50);
const displayLandmarkMinimumConfidence = 0.6;

class DisplayPoseStabilizer {
  DisplayPoseStabilizer({
    this.stationaryAlpha = 0.2,
    this.movingAlpha = 0.7,
    this.movementThreshold = 4,
    this.minimumConfidence = displayLandmarkMinimumConfidence,
  });

  final double stationaryAlpha;
  final double movingAlpha;
  final double movementThreshold;
  final double minimumConfidence;
  MappedPose? _previous;

  List<MappedPose> update(List<MappedPose> poses) {
    if (poses.isEmpty) {
      reset();
      return const [];
    }
    final candidate = poses.first;
    final stabilized = MappedPose({
      for (final entry in candidate.landmarks.entries)
        if (entry.value.confidence >= minimumConfidence)
          entry.key: _blendLandmark(
            _previous?.landmarks[entry.key],
            entry.value,
            _alphaFor(_previous?.landmarks[entry.key], entry.value),
          ),
    });
    _previous = stabilized;
    return stabilized.landmarks.isEmpty ? const [] : [stabilized];
  }

  double _alphaFor(LandmarkSample? previous, LandmarkSample current) {
    if (previous == null) return 1;
    final x = current.point.x - previous.point.x;
    final y = current.point.y - previous.point.y;
    return math.sqrt(x * x + y * y) > movementThreshold
        ? movingAlpha
        : stationaryAlpha;
  }

  void reset() => _previous = null;
}

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

List<MappedPose> smoothMappedPoses(
  List<MappedPose> previous,
  List<MappedPose> current, {
  double alpha = 0.75,
}) {
  if (previous.length != current.length || current.isEmpty) return current;
  return [
    for (var index = 0; index < current.length; index++)
      MappedPose({
        for (final entry in current[index].landmarks.entries)
          entry.key: _blendLandmark(
            previous[index].landmarks[entry.key],
            entry.value,
            alpha,
          ),
      }),
  ];
}

List<MappedPose> interpolateMappedPoses(
  List<MappedPose> start,
  List<MappedPose> end,
  double progress,
) => smoothMappedPoses(start, end, alpha: progress.clamp(0, 1));

LandmarkSample _blendLandmark(
  LandmarkSample? previous,
  LandmarkSample current,
  double alpha,
) {
  if (previous == null) return current;
  return LandmarkSample(
    point: Point2(
      previous.point.x + (current.point.x - previous.point.x) * alpha,
      previous.point.y + (current.point.y - previous.point.y) * alpha,
    ),
    confidence: current.confidence,
  );
}

class PoseOverlay extends StatefulWidget {
  const PoseOverlay({
    super.key,
    required this.poses,
    required this.imageSize,
    required this.rotationDegrees,
    required this.mirrored,
    this.interpolate = true,
  });

  final List<MappedPose> poses;
  final Size imageSize;
  final int rotationDegrees;
  final bool mirrored;
  final bool interpolate;

  @override
  State<PoseOverlay> createState() => _PoseOverlayState();
}

class _PoseOverlayState extends State<PoseOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final DisplayPoseStabilizer _stabilizer;
  late List<MappedPose> _from;
  late List<MappedPose> _target;

  @override
  void initState() {
    super.initState();
    _stabilizer = DisplayPoseStabilizer();
    _from = _stabilizer.update(widget.poses);
    _target = _from;
    _controller = AnimationController(
      vsync: this,
      duration: poseInterpolationDuration,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(PoseOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.poses, widget.poses)) return;
    final stabilized = _stabilizer.update(widget.poses);
    if (stabilized.isEmpty || !widget.interpolate) {
      _controller.stop();
      _from = stabilized;
      _target = stabilized;
      return;
    }
    _from = interpolateMappedPoses(_from, _target, _controller.value);
    _target = stabilized;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.interpolate || MediaQuery.disableAnimationsOf(context)) {
      return CustomPaint(
        painter: PosePainter(
          poses: _target,
          imageSize: widget.imageSize,
          rotationDegrees: widget.rotationDegrees,
          mirrored: widget.mirrored,
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: PosePainter(
          poses: interpolateMappedPoses(
            _from,
            _target,
            Curves.easeOut.transform(_controller.value),
          ),
          imageSize: widget.imageSize,
          rotationDegrees: widget.rotationDegrees,
          mirrored: widget.mirrored,
        ),
      ),
    );
  }
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
        if (start != null &&
            end != null &&
            start.confidence >= displayLandmarkMinimumConfidence &&
            end.confidence >= displayLandmarkMinimumConfidence) {
          canvas.drawLine(point(start), point(end), paint);
        }
      }
      for (final landmark in pose.landmarks.values.where(
        (landmark) => landmark.confidence >= displayLandmarkMinimumConfidence,
      )) {
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
