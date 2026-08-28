import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/models.dart';
import 'domain/exercise.dart';
import 'domain/feedback_catalog.dart';
import 'coaching_cues.dart';
import 'pose_painter.dart';
import 'pose_landmark_mapper.dart';
import 'pose_pipeline.dart';
import 'pose_pipeline_status.dart';
import 'session_controller.dart';
import 'settings_controller.dart';
import 'ui/app_theme.dart';

class PoseCameraPage extends ConsumerStatefulWidget {
  const PoseCameraPage({super.key});

  @override
  ConsumerState<PoseCameraPage> createState() => _PoseCameraPageState();
}

class _PoseCameraPageState extends ConsumerState<PoseCameraPage>
    with WidgetsBindingObserver {
  static const _settingsChannel = MethodChannel('right_posture/app_settings');
  late final PosePipeline _pipeline;
  late final CoachingCueCoordinator _cues;
  PosePipelineSnapshot? _consumedSnapshot;
  PosePipelineStatus _pipelineStatus = PosePipelineStatus.initializing;
  String? _pipelineError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cues = CoachingCueCoordinator.production();
    if (ref.read(settingsControllerProvider).ttsEnabled) {
      unawaited(_cues.prepare());
    }
    _pipeline = PosePipeline(
      exercise: ref.read(sessionControllerProvider).selectedExercise,
    )..addListener(_refresh);
    unawaited(_pipeline.start());
  }

  void _refresh() {
    if (!mounted) return;
    final snapshot = _pipeline.snapshot;
    final currentPhase = ref.read(sessionControllerProvider).phase;
    if (snapshot.status == PosePipelineStatus.noPerson ||
        snapshot.status == PosePipelineStatus.lowConfidence ||
        snapshot.status == PosePipelineStatus.failed) {
      _cues.interrupt();
      if (currentPhase == SessionPhase.tracking) {
        ref.read(sessionControllerProvider.notifier).trackingInterrupted();
      }
    }
    if (snapshot.status != _pipelineStatus ||
        snapshot.error != _pipelineError) {
      setState(() {
        _pipelineStatus = snapshot.status;
        _pipelineError = snapshot.error;
      });
    }
    if (!identical(snapshot, _consumedSnapshot)) {
      _consumedSnapshot = snapshot;
      final session = ref.read(sessionControllerProvider.notifier);
      final sessionState = ref.read(sessionControllerProvider);
      if (sessionState.phase == SessionPhase.preparing ||
          sessionState.phase == SessionPhase.countdown) {
        final imageSize = snapshot.imageSize;
        final pose = snapshot.poses.isEmpty ? null : snapshot.poses.first;
        session.acceptPreparationResult(
          sessionState.selectedExercise == ExerciseId.bicepCurl
              ? evaluateBicepCurlPlacement(
                  pose,
                  imageWidth: imageSize?.width ?? 0,
                  imageHeight: imageSize?.height ?? 0,
                )
              : evaluateSquatPlacement(
                  pose,
                  imageWidth: imageSize?.width ?? 0,
                  imageHeight: imageSize?.height ?? 0,
                ),
        );
      }
      if (snapshot.status == PosePipelineStatus.failed) {
        session.reportFailure(snapshot.error ?? 'Pose pipeline failed');
      } else if (sessionState.phase == SessionPhase.tracking) {
        if (sessionState.selectedExercise == ExerciseId.bicepCurl) {
          final sample = snapshot.bicepCurlSample;
          if (sample != null) session.acceptBicepCurlSample(sample);
        } else {
          final sample = snapshot.squatSample;
          if (sample != null) session.acceptPoseSample(sample);
        }
      }
    }
  }

  Future<void> _retry() async {
    ref.read(sessionControllerProvider.notifier).retry();
    await _pipeline.retry();
  }

  Future<void> _openSettings() async {
    try {
      await _settingsChannel.invokeMethod<void>('open');
    } on PlatformException {
      // Retry remains available when Android cannot open settings.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      unawaited(_pipeline.pause());
      ref.read(sessionControllerProvider.notifier).trackingInterrupted();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_pipeline.start());
    }
  }

  Future<void> _switchCamera() async {
    ref.read(sessionControllerProvider.notifier).trackingInterrupted();
    await _pipeline.switchCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pipeline.removeListener(_refresh);
    unawaited(_pipeline.close());
    unawaited(_cues.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    ref.listen(sessionControllerProvider, (_, next) {
      _cues.handle(
        preferences: ref.read(settingsControllerProvider),
        coaching: next.coaching,
        latestRep: next.latestFeedback,
      );
    });
    ref.listen(settingsControllerProvider, (previous, next) {
      if (next.ttsEnabled && !(previous?.ttsEnabled ?? false)) {
        unawaited(_cues.prepare());
      }
    });
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) ref.read(sessionControllerProvider.notifier).reset();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _CameraSurface(
                pipeline: _pipeline,
                onSwitchCamera: _switchCamera,
                onRetry: _retry,
                onOpenSettings: _openSettings,
              ),
              if ((session.phase == SessionPhase.preparing ||
                      session.phase == SessionPhase.countdown) &&
                  shouldShowLiveSessionHud(_pipelineStatus))
                Align(
                  alignment: Alignment.bottomCenter,
                  child: PreparationHud(
                    state: session,
                    exerciseName:
                        session.selectedExercise == ExerciseId.bicepCurl
                        ? bicepCurlExerciseProfile.displayName
                        : squatExerciseProfile.displayName,
                    instruction:
                        session.selectedExercise == ExerciseId.bicepCurl
                        ? bicepCurlExerciseProfile.setupInstruction
                        : squatExerciseProfile.setupInstruction,
                    onStart: ref
                        .read(sessionControllerProvider.notifier)
                        .startCountdown,
                  ),
                ),
              if (session.phase == SessionPhase.tracking &&
                  shouldShowLiveSessionHud(_pipelineStatus))
                Align(
                  alignment: Alignment.bottomCenter,
                  child: LiveSessionHud(
                    state: session,
                    pipelineStatus: _pipelineStatus,
                    pipelineError: _pipelineError,
                    onEnd: ref
                        .read(sessionControllerProvider.notifier)
                        .endSession,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

bool shouldShowLiveSessionHud(PosePipelineStatus status) =>
    status != PosePipelineStatus.failed;

class PreparationHud extends StatelessWidget {
  const PreparationHud({
    super.key,
    required this.state,
    required this.exerciseName,
    required this.instruction,
    required this.onStart,
  });

  final SessionState state;
  final String exerciseName;
  final String instruction;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final countdown = state.countdownValue;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 720,
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xEE15161B),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: countdown == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Set up your $exerciseName',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(instruction),
                    const SizedBox(height: AppSpacing.medium),
                    Semantics(
                      liveRegion: true,
                      label: state.placementGuidance,
                      child: Text(
                        state.placementGuidance ?? 'Checking position',
                        key: const Key('placement_guidance'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    FilledButton(
                      key: const Key('start_set'),
                      onPressed: state.placementStable ? onStart : null,
                      child: const Text('Start set'),
                    ),
                  ],
                )
              : Semantics(
                  liveRegion: true,
                  label: 'Starting in $countdown',
                  child: Text(
                    '$countdown',
                    key: const Key('countdown_value'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
        ),
      ),
    );
  }
}

class _CameraSurface extends StatelessWidget {
  const _CameraSurface({
    required this.pipeline,
    required this.onSwitchCamera,
    required this.onRetry,
    required this.onOpenSettings,
  });

  final PosePipeline pipeline;
  final VoidCallback onSwitchCamera;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pipeline,
      builder: (context, _) {
        final snapshot = pipeline.snapshot;
        final controller = pipeline.controller;
        if (snapshot.status == PosePipelineStatus.failed ||
            controller == null ||
            !controller.value.isInitialized) {
          return PosePipelineStatusPanel(
            snapshot: snapshot,
            exercise: pipeline.exercise,
            onRetry: onRetry,
            onOpenSettings: onOpenSettings,
          );
        }
        final orientation = controller.value.deviceOrientation;
        final landscape =
            orientation == DeviceOrientation.landscapeLeft ||
            orientation == DeviceOrientation.landscapeRight;
        final previewAspectRatio = landscape
            ? controller.value.aspectRatio
            : 1 / controller.value.aspectRatio;
        return Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: previewAspectRatio,
                child: ExcludeSemantics(
                  child: CameraPreview(
                    controller,
                    child: snapshot.imageSize == null
                        ? null
                        : RepaintBoundary(
                            child: PoseOverlay(
                              poses: snapshot.status == PosePipelineStatus.ready
                                  ? snapshot.poses
                                  : const [],
                              imageSize: snapshot.imageSize!,
                              rotationDegrees: snapshot.rotationDegrees,
                              mirrored: snapshot.mirrored,
                              interpolate:
                                  snapshot.status == PosePipelineStatus.ready,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: PosePipelineStatusPanel(
                snapshot: snapshot,
                exercise: pipeline.exercise,
                onRetry: onRetry,
                onOpenSettings: onOpenSettings,
              ),
            ),
            if (pipeline.canSwitchCamera)
              Positioned(
                top: 12,
                right: 12,
                child: IconButton.filled(
                  key: const Key('camera_switch_button'),
                  onPressed: onSwitchCamera,
                  icon: const Icon(Icons.cameraswitch),
                  tooltip: 'Switch camera',
                ),
              ),
          ],
        );
      },
    );
  }
}

class LiveSessionHud extends StatelessWidget {
  const LiveSessionHud({
    super.key,
    required this.state,
    required this.onEnd,
    this.pipelineStatus = PosePipelineStatus.ready,
    this.pipelineError,
  });

  final SessionState state;
  final VoidCallback onEnd;
  final PosePipelineStatus pipelineStatus;
  final String? pipelineError;

  @override
  Widget build(BuildContext context) {
    final calibrationCount = state.reps
        .where((rep) => rep.status == RepStatus.calibrating)
        .length;
    final latest = state.latestFeedback;
    final latestFeedbackText = latest == null ? null : feedbackForRep(latest);
    final trackingInterrupted =
        pipelineStatus == PosePipelineStatus.noPerson ||
        pipelineStatus == PosePipelineStatus.lowConfidence ||
        pipelineStatus == PosePipelineStatus.failed;
    final coaching = trackingInterrupted ? null : state.coaching;
    final (icon, color, status) = switch (pipelineStatus) {
      PosePipelineStatus.noPerson => (
        Icons.person_off,
        AppColors.warning,
        'Tracking paused. Step into frame',
      ),
      PosePipelineStatus.lowConfidence => (
        Icons.center_focus_weak,
        AppColors.warning,
        'Tracking paused. Show your full body',
      ),
      PosePipelineStatus.failed => (
        Icons.error,
        AppColors.degraded,
        'Tracking failed. ${pipelineError ?? 'Camera unavailable'}',
      ),
      _ => switch (latest?.status) {
        RepStatus.good => (Icons.check_circle, AppColors.lime, 'Good rep'),
        RepStatus.warning => (
          Icons.warning_amber,
          AppColors.warning,
          'Check form',
        ),
        RepStatus.degraded => (
          Icons.error,
          AppColors.degraded,
          'Form degraded',
        ),
        _ when calibrationCount < 3 => (
          Icons.tune,
          AppColors.textMuted,
          'Calibrating $calibrationCount of 3',
        ),
        _ => (Icons.track_changes, AppColors.lime, 'Tracking'),
      },
    };
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 720,
        maxHeight: MediaQuery.sizeOf(context).height * 0.6,
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0xEE15161B),
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.large),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (coaching != null) ...[
                Semantics(
                  liveRegion: true,
                  label: coachingText(coaching),
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.96, end: 1).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: child,
                      ),
                    ),
                    child: DecoratedBox(
                      key: ValueKey(coaching),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.medium,
                          vertical: AppSpacing.small,
                        ),
                        child: Text(
                          coachingText(coaching),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
              ],
              Row(
                children: [
                  Semantics(
                    label: '${state.reps.length} repetitions',
                    child: ExcludeSemantics(
                      child: Text(
                        '${state.reps.length}',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      label: status,
                      child: Row(
                        children: [
                          Icon(icon, color: color),
                          const SizedBox(width: AppSpacing.small),
                          Flexible(
                            child: Text(
                              status,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (calibrationCount < 3) ...[
                const SizedBox(height: AppSpacing.small),
                Semantics(
                  label: '$calibrationCount of 3 calibration reps complete',
                  child: LinearProgressIndicator(value: calibrationCount / 3),
                ),
              ],
              if (!trackingInterrupted && latestFeedbackText != null) ...[
                const SizedBox(height: AppSpacing.small),
                Text(
                  latestFeedbackText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: AppSpacing.medium),
              OutlinedButton(
                key: const Key('end_session'),
                onPressed: onEnd,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 52),
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.textMuted),
                  shape: const StadiumBorder(),
                ),
                child: const Text('End set'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
