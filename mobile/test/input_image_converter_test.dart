import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/input_image_converter.dart';

void main() {
  group('imageRotationDegrees', () {
    test('compensates back camera orientation', () {
      expect(
        imageRotationDegrees(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          lensDirection: CameraLensDirection.back,
        ),
        0,
      );
    });

    test('compensates front camera orientation', () {
      expect(
        imageRotationDegrees(
          sensorOrientation: 90,
          deviceOrientation: DeviceOrientation.landscapeLeft,
          lensDirection: CameraLensDirection.front,
        ),
        180,
      );
    });

    test('normalizes negative back-camera result', () {
      expect(
        imageRotationDegrees(
          sensorOrientation: 0,
          deviceOrientation: DeviceOrientation.landscapeRight,
          lensDirection: CameraLensDirection.back,
        ),
        90,
      );
    });
  });
}
