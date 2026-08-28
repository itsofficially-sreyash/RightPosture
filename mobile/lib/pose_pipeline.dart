import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import 'input_image_converter.dart';
import 'async_serial_queue.dart';
import 'pose_landmark_mapper.dart';
import 'domain/exercise.dart';

enum PosePipelineStatus { initializing, ready, noPerson, lowConfidence, failed }

enum PosePipelineFailureKind { permissionDenied, camera, processing }

class PosePipelineSnapshot {
  PosePipelineSnapshot({
    required this.status,
    List<MappedPose> poses = const [],
    this.squatSample,
    this.squatCandidate,
    this.bicepCurlSample,
    this.imageSize,
    this.rotationDegrees = 0,
    this.mirrored = false,
    this.processedFrames = 0,
    this.processingTime = Duration.zero,
    this.error,
    this.failureKind,
  }) : poses = List.unmodifiable(poses);

  final PosePipelineStatus status;
  final List<MappedPose> poses;
  final SquatFrameSample? squatSample;
  final SquatFrameSample? squatCandidate;
  final BicepCurlFrameSample? bicepCurlSample;
  final Size? imageSize;
  final int rotationDegrees;
  final bool mirrored;
  final int processedFrames;
  final Duration processingTime;
  final String? error;
  final PosePipelineFailureKind? failureKind;
}

class PosePipeline extends ChangeNotifier {
  PosePipeline({this.exercise = ExerciseId.squat})
    : _detector = PoseDetector(
        options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
      );

  final ExerciseId exercise;

  final PoseDetector _detector;
  final AsyncSerialQueue _lifecycle = AsyncSerialQueue();
  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  int _generation = 0;
  bool _processing = false;
  bool _closed = false;
  int _consecutiveFrameFailures = 0;
  Future<void>? _activeProcessing;
  PosePipelineSnapshot _snapshot = PosePipelineSnapshot(
    status: PosePipelineStatus.initializing,
  );

  CameraController? get controller => _controller;
  PosePipelineSnapshot get snapshot => _snapshot;

  Future<void> start() => _lifecycle.run(_start);

  Future<void> _start() async {
    if (_closed || _controller != null) return;
    final generation = ++_generation;
    CameraController? openingController;
    _publish(PosePipelineSnapshot(status: PosePipelineStatus.initializing));
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        final back = _cameras.indexWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
        );
        _cameraIndex = back < 0 ? 0 : back;
      }
      if (_cameras.isEmpty) throw StateError('No camera found');
      final camera = _cameras[_cameraIndex.clamp(0, _cameras.length - 1)];
      final controller = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      openingController = controller;
      await controller.initialize();
      if (_closed || generation != _generation) {
        await controller.dispose();
        return;
      }
      _controller = controller;
      openingController = null;
      await controller.startImageStream(
        (image) => _acceptFrame(image, camera, controller, generation),
      );
      _publish(PosePipelineSnapshot(status: PosePipelineStatus.ready));
    } on CameraException catch (error) {
      await openingController?.dispose();
      await _stopCamera();
      _publish(
        PosePipelineSnapshot(
          status: PosePipelineStatus.failed,
          error: error.description ?? error.code,
          failureKind: cameraFailureKind(error.code),
        ),
      );
    } catch (error) {
      await openingController?.dispose();
      await _stopCamera();
      _publish(
        PosePipelineSnapshot(
          status: PosePipelineStatus.failed,
          error: error.toString(),
          failureKind: PosePipelineFailureKind.camera,
        ),
      );
    }
  }

  void _acceptFrame(
    CameraImage image,
    CameraDescription camera,
    CameraController controller,
    int generation,
  ) {
    if (_processing || _closed || generation != _generation) return;
    _processing = true;
    final processing = _processFrame(image, camera, controller, generation);
    _activeProcessing = processing;
    unawaited(processing);
  }

  Future<void> _processFrame(
    CameraImage image,
    CameraDescription camera,
    CameraController controller,
    int generation,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final input = inputImageFromCameraImage(
        image: image,
        camera: camera,
        deviceOrientation: controller.value.deviceOrientation,
      );
      if (input == null) return;
      final poses = await _detector.processImage(input);
      if (_closed || generation != _generation) return;
      final mapped = mapPoses(poses);
      _consecutiveFrameFailures = 0;
      final exerciseSampleReady = switch (exercise) {
        ExerciseId.bicepCurl => mapped.bicepCurlSample != null,
        _ => mapped.squatSample != null,
      };
      final status = poses.isEmpty
          ? PosePipelineStatus.noPerson
          : !exerciseSampleReady
          ? PosePipelineStatus.lowConfidence
          : PosePipelineStatus.ready;
      _publish(
        PosePipelineSnapshot(
          status: status,
          poses: mapped.poses,
          squatSample: mapped.squatSample,
          squatCandidate: mapped.squatCandidate,
          bicepCurlSample: mapped.bicepCurlSample,
          imageSize: input.metadata?.size,
          rotationDegrees: _rotationDegrees(input.metadata?.rotation),
          mirrored: camera.lensDirection == CameraLensDirection.front,
          processedFrames: _snapshot.processedFrames + 1,
          processingTime: stopwatch.elapsed,
        ),
      );
    } catch (error) {
      _consecutiveFrameFailures++;
      if (_consecutiveFrameFailures >= 3) {
        _publish(
          PosePipelineSnapshot(
            status: PosePipelineStatus.failed,
            error: 'Pose processing failed: $error',
            failureKind: PosePipelineFailureKind.processing,
          ),
        );
      }
    } finally {
      _processing = false;
    }
  }

  bool get canSwitchCamera {
    final controller = _controller;
    if (controller == null) return false;
    return oppositeLensCameraIndex(
          _cameras,
          controller.description.lensDirection,
        ) >=
        0;
  }

  Future<void> switchCamera() async {
    final controller = _controller;
    if (controller == null) return;
    final next = oppositeLensCameraIndex(
      _cameras,
      controller.description.lensDirection,
    );
    if (next < 0) return;
    _cameraIndex = next;
    await pause();
    await start();
  }

  Future<void> retry() async {
    await pause();
    _consecutiveFrameFailures = 0;
    await start();
  }

  Future<void> pause() {
    _generation++;
    return _lifecycle.run(_stopCamera);
  }

  Future<void> _stopCamera() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    if (controller.value.isStreamingImages) await controller.stopImageStream();
    await _activeProcessing;
    await controller.dispose();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _generation++;
    await _lifecycle.run(_stopCamera);
    await _detector.close();
    super.dispose();
  }

  void _publish(PosePipelineSnapshot value) {
    if (_closed) return;
    _snapshot = value;
    notifyListeners();
  }
}

int oppositeLensCameraIndex(
  List<CameraDescription> cameras,
  CameraLensDirection currentDirection,
) {
  final target = currentDirection == CameraLensDirection.front
      ? CameraLensDirection.back
      : CameraLensDirection.front;
  return cameras.indexWhere((camera) => camera.lensDirection == target);
}

PosePipelineFailureKind cameraFailureKind(String code) => switch (code) {
  'CameraAccessDenied' ||
  'CameraAccessDeniedWithoutPrompt' ||
  'CameraAccessRestricted' => PosePipelineFailureKind.permissionDenied,
  _ => PosePipelineFailureKind.camera,
};

int _rotationDegrees(InputImageRotation? rotation) => switch (rotation) {
  InputImageRotation.rotation90deg => 90,
  InputImageRotation.rotation180deg => 180,
  InputImageRotation.rotation270deg => 270,
  _ => 0,
};
