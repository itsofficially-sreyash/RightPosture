import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/models.dart';
import 'domain/checkpoint_tts.dart';
import 'domain/exercise.dart';
import 'domain/feedback_catalog.dart';
import 'domain/history.dart';
import 'domain/exercise_registry.dart';
import 'coaching_cues.dart';
import 'history_storage.dart';
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
  late final Future<List<HistoryWorkout>> _historyFuture;
  final MidpointCheckpoint _midpoint = MidpointCheckpoint();
  Future<void>? _preSetSpeech;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cues = CoachingCueCoordinator.production();
    _cues.setForeground(
      WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
    _historyFuture = ref.read(historyStorageProvider).load();
    if (ref.read(settingsControllerProvider).ttsEnabled) {
      unawaited(_cues.prepare());
    }
    _pipeline = PosePipeline(
      exercise: ref.read(sessionControllerProvider).selectedExercise,
    )..addListener(_refresh);
    ref.listenManual(sessionControllerProvider, (_, next) {
      _cues.handleRepCue(
        preferences: ref.read(settingsControllerProvider),
        sessionId:
            '${next.selectedExercise.name}:'
            '${next.workout.completedSets.length + 1}',
        latestRep: next.latestFeedback,
      );
      if (next.phase == SessionPhase.tracking && _preSetSpeech == null) {
        _preSetSpeech = _speakPreSet(next);
      }
      if (next.phase == SessionPhase.tracking &&
          _midpoint.shouldFire(
            completedReps: next.reps.length,
            targetRepCount: next.targetRepCount,
          )) {
        unawaited(_speakMidSet(next));
      }
    });
    ref.listenManual(settingsControllerProvider, (previous, next) {
      if (next.ttsEnabled && !(previous?.ttsEnabled ?? false)) {
        unawaited(_cues.prepare());
      }
    });
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
        session.acceptPreparationResult(switch (sessionState.selectedExercise) {
          ExerciseId.bicepCurl ||
          ExerciseId.lateralRaise ||
          ExerciseId.shoulderPress => evaluateBicepCurlPlacement(
            pose,
            imageWidth: imageSize?.width ?? 0,
            imageHeight: imageSize?.height ?? 0,
          ),
          _ => evaluateSquatPlacement(
            pose,
            imageWidth: imageSize?.width ?? 0,
            imageHeight: imageSize?.height ?? 0,
          ),
        });
      }
      if (snapshot.status == PosePipelineStatus.failed) {
        session.reportFailure(snapshot.error ?? 'Pose pipeline failed');
      } else if (sessionState.phase == SessionPhase.tracking) {
        switch (sessionState.selectedExercise) {
          case ExerciseId.bicepCurl:
            final sample = snapshot.bicepCurlSample;
            if (sample != null) session.acceptBicepCurlSample(sample);
          case ExerciseId.lateralRaise:
            final sample = snapshot.lateralRaiseSample;
            if (sample != null) session.acceptLateralRaiseSample(sample);
          case ExerciseId.shoulderPress:
            final sample = snapshot.lateralRaiseSample;
            if (sample != null) session.acceptShoulderPressSample(sample);
          default:
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
      _cues.setForeground(false);
      ref.read(sessionControllerProvider.notifier).trackingInterrupted();
    } else if (state == AppLifecycleState.resumed) {
      _cues.setForeground(true);
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
    final profile = const ExerciseRegistry().profileFor(
      session.selectedExercise,
    );
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
              PoseCameraSurface(
                pipeline: _pipeline,
                onSwitchCamera: _switchCamera,
                onRetry: _retry,
                onOpenSettings: _openSettings,
                showCameraControls: false,
              ),
              Align(
                alignment: Alignment.topCenter,
                child: CameraSessionTopBar(
                  status: _pipelineStatus,
                  tracking: session.phase == SessionPhase.tracking,
                  canSwitchCamera: _pipeline.canSwitchCamera,
                  onClose: ref.read(sessionControllerProvider.notifier).reset,
                  onSwitchCamera: _switchCamera,
                ),
              ),
              if ((session.phase == SessionPhase.preparing ||
                      session.phase == SessionPhase.countdown) &&
                  shouldShowLiveSessionHud(_pipelineStatus))
                Align(
                  alignment: Alignment.bottomCenter,
                  child: PreparationHud(
                    state: session,
                    exerciseName: profile.displayName,
                    instruction: profile.setupInstruction,
                    onStart: ref
                        .read(sessionControllerProvider.notifier)
                        .startCountdown,
                    onTargetChanged: ref
                        .read(sessionControllerProvider.notifier)
                        .setTargetRepCount,
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

  Future<void> _speakPreSet(SessionState session) async {
    final stored = await _historyFuture;
    if (!mounted ||
        ref.read(sessionControllerProvider).phase != SessionPhase.tracking) {
      return;
    }
    final previous = [
      ...stored.expand((workout) => workout.sets),
      ...session.workout.completedSets.map(HistorySet.fromCompletedSet),
    ];
    _cues.speak(
      preSetCheckpointMessage(session.selectedExercise, previous),
      enabled: ref.read(settingsControllerProvider).ttsEnabled,
    );
  }

  Future<void> _speakMidSet(SessionState session) async {
    await _preSetSpeech;
    if (!mounted ||
        ref.read(sessionControllerProvider).phase != SessionPhase.tracking) {
      return;
    }
    _cues.speak(
      midSetCheckpointMessage(session.selectedExercise, session.reps),
      enabled: ref.read(settingsControllerProvider).ttsEnabled,
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
    this.onTargetChanged,
  });

  final SessionState state;
  final String exerciseName;
  final String instruction;
  final VoidCallback onStart;
  final ValueChanged<int?>? onTargetChanged;

  @override
  Widget build(BuildContext context) {
    final countdown = state.countdownValue;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        88,
        AppSpacing.medium,
        AppSpacing.medium,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: SingleChildScrollView(
          child: countdown == null
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceGlass,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(color: AppColors.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Set up your $exerciseName',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(color: AppColors.lime),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          instruction,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        const Divider(color: AppColors.outlineVariant),
                        const SizedBox(height: AppSpacing.small),
                        const Text(
                          'TARGET REPS',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        _RepTargetPicker(
                          selected: state.targetRepCount,
                          onChanged: onTargetChanged,
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Semantics(
                          liveRegion: true,
                          label: state.placementGuidance,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                state.placementStable
                                    ? Icons.check_circle
                                    : Icons.center_focus_weak,
                                color: state.placementStable
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                              const SizedBox(width: AppSpacing.small),
                              Expanded(
                                child: Text(
                                  state.placementGuidance ??
                                      'Checking camera position',
                                  key: const Key('placement_guidance'),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        FilledButton.icon(
                          key: const Key('start_set'),
                          onPressed: state.placementStable ? onStart : null,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('START SET'),
                        ),
                      ],
                    ),
                  ),
                )
              : Semantics(
                  liveRegion: true,
                  label: 'Starting in $countdown',
                  child: Text(
                    '$countdown',
                    key: const Key('countdown_value'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.lime,
                      fontSize: 112,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _RepTargetPicker extends StatelessWidget {
  const _RepTargetPicker({required this.selected, required this.onChanged});

  final int? selected;
  final ValueChanged<int?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final target in const <int?>[8, 10, 12, null]) ...[
          if (target != 8) const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Semantics(
              selected: selected == target,
              button: true,
              label: target == null ? 'Open set' : '$target repetitions',
              child: ChoiceChip(
                key: Key('target_${target ?? 'open'}'),
                showCheckmark: false,
                label: SizedBox(
                  width: double.infinity,
                  child: Text(
                    target == null ? '∞' : '$target',
                    textAlign: TextAlign.center,
                  ),
                ),
                selected: selected == target,
                onSelected: onChanged == null
                    ? null
                    : (value) {
                        if (value) onChanged!(target);
                      },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class CameraSessionTopBar extends StatelessWidget {
  const CameraSessionTopBar({
    super.key,
    required this.status,
    required this.tracking,
    required this.canSwitchCamera,
    required this.onClose,
    required this.onSwitchCamera,
  });

  final PosePipelineStatus status;
  final bool tracking;
  final bool canSwitchCamera;
  final VoidCallback onClose;
  final VoidCallback onSwitchCamera;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      PosePipelineStatus.initializing => ('STARTING CAMERA', AppColors.warning),
      PosePipelineStatus.ready => (
        tracking ? 'TRACKING' : 'CAMERA READY',
        tracking ? AppColors.degraded : AppColors.success,
      ),
      PosePipelineStatus.noPerson => ('WAITING FOR USER', AppColors.warning),
      PosePipelineStatus.lowConfidence => (
        'ADJUST POSITION',
        AppColors.warning,
      ),
      PosePipelineStatus.failed => ('CAMERA ERROR', AppColors.degraded),
    };
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.medium),
      child: Row(
        children: [
          _CameraActionButton(
            key: const Key('close_camera_session'),
            tooltip: 'Close workout',
            icon: Icons.close,
            onPressed: onClose,
          ),
          const Spacer(),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceGlass,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: AppColors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.medium,
                vertical: AppSpacing.small,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _CameraActionButton(
            key: const Key('camera_switch_button'),
            tooltip: 'Switch camera',
            icon: Icons.cameraswitch_outlined,
            onPressed: canSwitchCamera ? onSwitchCamera : null,
          ),
        ],
      ),
    );
  }
}

class _CameraActionButton extends StatelessWidget {
  const _CameraActionButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        backgroundColor: AppColors.surfaceGlass,
        foregroundColor: AppColors.lime,
        disabledForegroundColor: AppColors.textMuted,
        side: const BorderSide(color: AppColors.outlineVariant),
      ),
      icon: Icon(icon),
    );
  }
}

class PoseCameraSurface extends StatelessWidget {
  const PoseCameraSurface({
    super.key,
    required this.pipeline,
    required this.onSwitchCamera,
    required this.onRetry,
    required this.onOpenSettings,
    this.showCameraControls = true,
  });

  final PosePipeline pipeline;
  final VoidCallback onSwitchCamera;
  final VoidCallback onRetry;
  final VoidCallback onOpenSettings;
  final bool showCameraControls;

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
            if (showCameraControls)
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
            if (showCameraControls && pipeline.canSwitchCamera)
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.medium,
        88,
        AppSpacing.medium,
        AppSpacing.medium,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                label: coaching == null ? status : coachingText(coaching),
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
                  child: _CoachingToast(
                    key: ValueKey(coaching ?? status),
                    icon: coaching == null ? icon : Icons.info_outline,
                    color: coaching == null ? color : AppColors.cyan,
                    message: coaching == null ? status : coachingText(coaching),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Semantics(
                label: state.targetRepCount == null
                    ? '${state.reps.length} repetitions, open target'
                    : '${state.reps.length} of ${state.targetRepCount} repetitions',
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${state.reps.length}',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  color: AppColors.lime,
                                  fontSize: 120,
                                  height: 0.95,
                                ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.small,
                          bottom: AppSpacing.medium,
                        ),
                        child: Text(
                          state.targetRepCount == null
                              ? '/ ∞'
                              : '/ ${state.targetRepCount}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (calibrationCount < 3) ...[
                Semantics(
                  label: '$calibrationCount of 3 calibration reps complete',
                  child: LinearProgressIndicator(
                    value: calibrationCount / 3,
                    color: AppColors.cyan,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
              ],
              if (!trackingInterrupted && latestFeedbackText != null) ...[
                Text(
                  latestFeedbackText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.small),
              ],
              _RepProgressTimeline(
                completed: state.reps.length,
                target: state.targetRepCount,
              ),
              const SizedBox(height: AppSpacing.medium),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 200),
                  child: OutlinedButton.icon(
                    key: const Key('end_session'),
                    onPressed: onEnd,
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: const Text('END SET'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoachingToast extends StatelessWidget {
  const _CoachingToast({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceGlass,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border(top: BorderSide(color: color, width: 4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.medium,
          vertical: AppSpacing.small,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.small),
            Flexible(
              child: Text(
                message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepProgressTimeline extends StatelessWidget {
  const _RepProgressTimeline({required this.completed, required this.target});

  final int completed;
  final int? target;

  @override
  Widget build(BuildContext context) {
    final nodeCount = target ?? (completed < 5 ? 5 : completed.clamp(5, 12));
    return Semantics(
      label: target == null
          ? '$completed repetitions completed in open set'
          : '$completed of $target repetitions completed',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceGlass,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.medium,
              vertical: AppSpacing.small,
            ),
            child: Row(
              children: [
                for (var index = 0; index < nodeCount; index++) ...[
                  if (index > 0)
                    Expanded(
                      child: Container(
                        height: 2,
                        color: index <= completed
                            ? AppColors.cyan
                            : AppColors.outlineVariant,
                      ),
                    ),
                  Container(
                    width: index < completed ? 12 : 8,
                    height: index < completed ? 12 : 8,
                    decoration: BoxDecoration(
                      color: index < completed
                          ? AppColors.lime
                          : AppColors.outlineVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
