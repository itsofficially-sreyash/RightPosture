import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

const deviceOrientationDegrees = <DeviceOrientation, int>{
  DeviceOrientation.portraitUp: 0,
  DeviceOrientation.landscapeLeft: 90,
  DeviceOrientation.portraitDown: 180,
  DeviceOrientation.landscapeRight: 270,
};

int imageRotationDegrees({
  required int sensorOrientation,
  required DeviceOrientation deviceOrientation,
  required CameraLensDirection lensDirection,
}) {
  final deviceDegrees = deviceOrientationDegrees[deviceOrientation]!;
  return lensDirection == CameraLensDirection.front
      ? (sensorOrientation + deviceDegrees) % 360
      : (sensorOrientation - deviceDegrees + 360) % 360;
}

InputImage? inputImageFromCameraImage({
  required CameraImage image,
  required CameraDescription camera,
  required DeviceOrientation deviceOrientation,
}) {
  final rotationDegrees = Platform.isIOS
      ? camera.sensorOrientation
      : imageRotationDegrees(
          sensorOrientation: camera.sensorOrientation,
          deviceOrientation: deviceOrientation,
          lensDirection: camera.lensDirection,
        );
  final rotation = InputImageRotationValue.fromRawValue(rotationDegrees);
  final format = InputImageFormatValue.fromRawValue(image.format.raw);
  if (rotation == null || format == null || image.planes.length != 1) {
    return null;
  }
  if (Platform.isAndroid && format != InputImageFormat.nv21) return null;
  if (Platform.isIOS && format != InputImageFormat.bgra8888) return null;

  final plane = image.planes.first;
  return InputImage.fromBytes(
    bytes: plane.bytes,
    metadata: InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: plane.bytesPerRow,
    ),
  );
}
