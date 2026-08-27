import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
