import 'package:camera/camera.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/pose_pipeline.dart';

void main() {
  const backWide = CameraDescription(
    name: 'back-wide',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90,
  );
  const backTelephoto = CameraDescription(
    name: 'back-telephoto',
    lensDirection: CameraLensDirection.back,
    sensorOrientation: 90,
  );
  const front = CameraDescription(
    name: 'front',
    lensDirection: CameraLensDirection.front,
    sensorOrientation: 270,
  );

  test('selects front camera instead of another rear camera', () {
    expect(
      oppositeLensCameraIndex(const [
        backWide,
        backTelephoto,
        front,
      ], CameraLensDirection.back),
      2,
    );
  });

  test('selects back camera from front camera', () {
    expect(
      oppositeLensCameraIndex(const [
        front,
        backWide,
      ], CameraLensDirection.front),
      1,
    );
  });

  test('returns unavailable when opposite lens does not exist', () {
    expect(
      oppositeLensCameraIndex(const [
        backWide,
        backTelephoto,
      ], CameraLensDirection.back),
      -1,
    );
  });
}
