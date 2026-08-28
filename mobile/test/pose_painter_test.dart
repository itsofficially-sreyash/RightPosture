import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/domain/joint_angle.dart';
import 'package:right_posture/pose_landmark_mapper.dart';
import 'package:right_posture/pose_painter.dart';

void main() {
  const image = Size(640, 480);
  const canvas = Size(480, 640);

  test('maps asymmetric rotated portrait coordinates', () {
    expect(
      translatePosePoint(
        point: const Offset(120, 160),
        canvasSize: canvas,
        imageSize: image,
        rotationDegrees: 90,
        mirrored: false,
      ),
      const Offset(120, 160),
    );
  });

  test('mirrors front camera coordinates', () {
    expect(
      translatePosePoint(
        point: const Offset(64, 48),
        canvasSize: const Size(640, 480),
        imageSize: image,
        rotationDegrees: 0,
        mirrored: true,
      ),
      const Offset(576, 48),
    );
  });

  test('mirrors 270 degree rotation coordinates', () {
    expect(
      translatePosePoint(
        point: const Offset(0, 0),
        canvasSize: canvas,
        imageSize: image,
        rotationDegrees: 270,
        mirrored: false,
      ),
      const Offset(480, 0),
    );
  });

  test('maps 180 degree coordinates without portrait stretching', () {
    expect(
      translatePosePoint(
        point: const Offset(64, 96),
        canvasSize: const Size(640, 480),
        imageSize: image,
        rotationDegrees: 180,
        mirrored: false,
      ),
      const Offset(64, 96),
    );
  });

  test('center-crops a mismatched aspect ratio', () {
    expect(
      translatePosePoint(
        point: const Offset(0, 0),
        canvasSize: const Size(300, 300),
        imageSize: const Size(400, 200),
        rotationDegrees: 0,
        mirrored: false,
      ),
      const Offset(-150, 0),
    );
  });

  test('handles mirrored front camera at 90 degrees', () {
    expect(
      translatePosePoint(
        point: const Offset(0, 0),
        canvasSize: canvas,
        imageSize: image,
        rotationDegrees: 90,
        mirrored: true,
      ),
      Offset.zero,
    );
  });

  test('smooths and interpolates display landmarks only', () {
    final start = [
      MappedPose({
        BodyJoint.leftKnee: const LandmarkSample(
          point: Point2(0, 0),
          confidence: 0.8,
        ),
      }),
    ];
    final end = [
      MappedPose({
        BodyJoint.leftKnee: const LandmarkSample(
          point: Point2(100, 40),
          confidence: 0.9,
        ),
      }),
    ];

    final smoothed = smoothMappedPoses(start, end);
    expect(smoothed.single.landmarks[BodyJoint.leftKnee]!.point.x, 75);
    expect(smoothed.single.landmarks[BodyJoint.leftKnee]!.confidence, 0.9);
    final halfway = interpolateMappedPoses(start, smoothed, 0.5);
    expect(halfway.single.landmarks[BodyJoint.leftKnee]!.point.x, 37.5);
  });

  test('tracking loss clears display landmarks without interpolation', () {
    final start = [
      MappedPose({
        BodyJoint.leftKnee: const LandmarkSample(
          point: Point2(10, 10),
          confidence: 0.9,
        ),
      }),
    ];
    expect(smoothMappedPoses(start, const []), isEmpty);
  });

  test('display stabilizer damps stationary landmark jitter', () {
    final stabilizer = DisplayPoseStabilizer();
    stabilizer.update([
      MappedPose({
        BodyJoint.leftKnee: const LandmarkSample(
          point: Point2(100, 100),
          confidence: 0.9,
        ),
      }),
    ]);

    final result = stabilizer.update([
      MappedPose({
        BodyJoint.leftKnee: const LandmarkSample(
          point: Point2(102, 98),
          confidence: 0.9,
        ),
      }),
    ]);

    final point = result.single.landmarks[BodyJoint.leftKnee]!.point;
    expect(point.x, 100.4);
    expect(point.y, 99.6);
  });

  test('display stabilizer follows intentional movement quickly', () {
    final stabilizer = DisplayPoseStabilizer();
    stabilizer.update([
      MappedPose({
        BodyJoint.leftWrist: const LandmarkSample(
          point: Point2(10, 10),
          confidence: 0.9,
        ),
      }),
    ]);

    final result = stabilizer.update([
      MappedPose({
        BodyJoint.leftWrist: const LandmarkSample(
          point: Point2(30, 10),
          confidence: 0.9,
        ),
      }),
    ]);

    expect(result.single.landmarks[BodyJoint.leftWrist]!.point.x, 24);
  });

  test('display stabilizer filters weak joints and phantom poses', () {
    final stabilizer = DisplayPoseStabilizer();
    final result = stabilizer.update([
      MappedPose({
        BodyJoint.leftKnee: const LandmarkSample(
          point: Point2(10, 10),
          confidence: 0.9,
        ),
        BodyJoint.leftAnkle: const LandmarkSample(
          point: Point2(20, 20),
          confidence: 0.2,
        ),
      }),
      MappedPose({
        BodyJoint.rightKnee: const LandmarkSample(
          point: Point2(90, 90),
          confidence: 0.9,
        ),
      }),
    ]);

    expect(result, hasLength(1));
    expect(result.single.landmarks, contains(BodyJoint.leftKnee));
    expect(result.single.landmarks, isNot(contains(BodyJoint.leftAnkle)));
    expect(result.single.landmarks, isNot(contains(BodyJoint.rightKnee)));
  });

  test('display stabilizer resets after tracking loss', () {
    final stabilizer = DisplayPoseStabilizer();
    stabilizer.update([
      MappedPose({
        BodyJoint.leftKnee: const LandmarkSample(
          point: Point2(10, 10),
          confidence: 0.9,
        ),
      }),
    ]);
    expect(stabilizer.update(const []), isEmpty);

    final result = stabilizer.update([
      MappedPose({
        BodyJoint.leftKnee: const LandmarkSample(
          point: Point2(90, 90),
          confidence: 0.9,
        ),
      }),
    ]);
    expect(result.single.landmarks[BodyJoint.leftKnee]!.point.x, 90);
  });

  testWidgets('reduced motion bypasses overlay animation', (tester) async {
    final poses = [
      MappedPose({
        BodyJoint.leftKnee: const LandmarkSample(
          point: Point2(10, 10),
          confidence: 0.9,
        ),
      }),
    ];
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: PoseOverlay(
            poses: poses,
            imageSize: const Size(100, 100),
            rotationDegrees: 0,
            mirrored: false,
          ),
        ),
      ),
    );

    expect(find.byType(AnimatedBuilder), findsNothing);
    expect(find.byType(CustomPaint), findsOneWidget);
    expect(poseInterpolationDuration, const Duration(milliseconds: 50));
  });
}
