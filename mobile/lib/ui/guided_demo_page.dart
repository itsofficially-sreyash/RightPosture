import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coaching_cues.dart';
import '../domain/exercise.dart';
import '../domain/exercise_registry.dart';
import '../domain/guided_demo.dart';
import '../history_storage.dart';
import '../pose_camera_page.dart';
import '../pose_pipeline.dart';
import '../settings_controller.dart';
import 'app_theme.dart';

Future<void> finishGuidedDemoTransition({
  required Future<void> Function() closeCamera,
  required Future<void> Function() persistVisit,
}) async {
  await closeCamera();
  await persistVisit();
}

class GuidedDemoPage extends ConsumerStatefulWidget {
  const GuidedDemoPage({super.key, required this.exercise});

  final ExerciseId exercise;

  @override
  ConsumerState<GuidedDemoPage> createState() => _GuidedDemoPageState();
}

class _GuidedDemoPageState extends ConsumerState<GuidedDemoPage>
    with WidgetsBindingObserver {
  static const _settingsChannel = MethodChannel('right_posture/app_settings');
  late final PosePipeline _pipeline;
  late final CoachingCueCoordinator _cues;
  late final GuidedDemoRepTracker _tracker;
  late String _instruction;
  PosePipelineStatus _status = PosePipelineStatus.initializing;
  Timer? _finishTimer;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tracker = GuidedDemoRepTracker(
      const ExerciseRegistry().detectorFor(widget.exercise),
    );
    _instruction = const ExerciseRegistry()
        .profileFor(widget.exercise)
        .setupInstruction;
    _cues = CoachingCueCoordinator.production();
    if (ref.read(settingsControllerProvider).ttsEnabled) {
      unawaited(_cues.prepare());
      _cues.speak(_instruction, enabled: true);
    }
    _pipeline = PosePipeline(exercise: widget.exercise)..addListener(_refresh);
    unawaited(_pipeline.start());
  }

  void _refresh() {
    if (!mounted) return;
    final snapshot = _pipeline.snapshot;
    if (snapshot.status != PosePipelineStatus.ready) {
      _cues.interrupt();
      _tracker.resetAttempt();
      if (_status != snapshot.status) setState(() => _status = snapshot.status);
      return;
    }
    final values = _valuesFor(snapshot);
    final selected = guidedDemoInstruction(widget.exercise, values);
    final movement = _movementFor(snapshot);
    if (movement == null) {
      if (_status != snapshot.status ||
          (selected != null && selected != _instruction)) {
        setState(() {
          _status = snapshot.status;
          if (selected != null) _instruction = selected;
        });
      }
      return;
    }
    final completed = _tracker.accept(
      frame: snapshot.processedFrames,
      movement: movement,
    );
    if (completed || selected != null && selected != _instruction) {
      final message = completed
          ? 'Practice rep ${_tracker.completedReps} of '
                '${_tracker.targetReps} complete.'
          : selected!;
      setState(() {
        _status = snapshot.status;
        _instruction = message;
      });
      _cues.speak(
        message,
        enabled: ref.read(settingsControllerProvider).ttsEnabled,
      );
    } else if (_status != snapshot.status) {
      setState(() => _status = snapshot.status);
    }
    if (_tracker.isComplete && _finishTimer == null) {
      _finishTimer = Timer(const Duration(seconds: 2), _finish);
    }
  }

  MovementFrame? _movementFor(PosePipelineSnapshot snapshot) {
    final now = DateTime.now();
    switch (widget.exercise) {
      case ExerciseId.squat:
        final sample = snapshot.squatSample;
        if (sample == null) return null;
        return MovementFrame(
          timestamp: now,
          values: {MovementMetric.kneeAngle: sample.kneeAngle},
          confidence: {MovementMetric.kneeAngle: sample.confidence},
          trackedSide: switch (sample.side) {
            'left' => TrackedSide.left,
            'right' => TrackedSide.right,
            _ => TrackedSide.unknown,
          },
        );
      case ExerciseId.bicepCurl:
        final sample = snapshot.bicepCurlSample;
        if (sample == null) return null;
        return MovementFrame(
          timestamp: now,
          values: {
            MovementMetric.leftElbowAngle: sample.leftElbowAngle,
            MovementMetric.rightElbowAngle: sample.rightElbowAngle,
            MovementMetric.torsoVerticalPosition: sample.torsoVerticalPosition,
          },
          confidence: {
            MovementMetric.leftElbowAngle: sample.leftConfidence,
            MovementMetric.rightElbowAngle: sample.rightConfidence,
            MovementMetric.torsoVerticalPosition: sample.torsoConfidence,
          },
          trackedSide: TrackedSide.bilateral,
        );
      case ExerciseId.lateralRaise || ExerciseId.shoulderPress:
        final sample = snapshot.lateralRaiseSample;
        if (sample == null) return null;
        return MovementFrame(
          timestamp: now,
          values: {
            MovementMetric.leftArmElevation: sample.leftArmElevation,
            MovementMetric.rightArmElevation: sample.rightArmElevation,
            MovementMetric.leftElbowAngle: sample.leftElbowAngle,
            MovementMetric.rightElbowAngle: sample.rightElbowAngle,
            MovementMetric.torsoLean: sample.torsoLean,
          },
          confidence: {
            MovementMetric.leftArmElevation: sample.leftConfidence,
            MovementMetric.rightArmElevation: sample.rightConfidence,
            MovementMetric.leftElbowAngle: sample.leftConfidence,
            MovementMetric.rightElbowAngle: sample.rightConfidence,
            MovementMetric.torsoLean: sample.torsoConfidence,
          },
          trackedSide: TrackedSide.bilateral,
        );
      case ExerciseId.reverseLunge || ExerciseId.jumpingJack:
        return null;
    }
  }

  Map<MovementMetric, double> _valuesFor(PosePipelineSnapshot snapshot) {
    switch (widget.exercise) {
      case ExerciseId.squat:
        final sample = snapshot.squatSample;
        return sample == null
            ? const {}
            : {MovementMetric.kneeAngle: sample.kneeAngle};
      case ExerciseId.bicepCurl:
        final sample = snapshot.bicepCurlSample;
        return sample == null
            ? const {}
            : {
                MovementMetric.leftElbowAngle: sample.leftElbowAngle,
                MovementMetric.rightElbowAngle: sample.rightElbowAngle,
              };
      case ExerciseId.lateralRaise || ExerciseId.shoulderPress:
        final sample = snapshot.lateralRaiseSample;
        return sample == null
            ? const {}
            : {
                MovementMetric.leftArmElevation: sample.leftArmElevation,
                MovementMetric.rightArmElevation: sample.rightArmElevation,
                MovementMetric.leftElbowAngle: sample.leftElbowAngle,
                MovementMetric.rightElbowAngle: sample.rightElbowAngle,
              };
      case ExerciseId.reverseLunge || ExerciseId.jumpingJack:
        return const {};
    }
  }

  Future<void> _finish() async {
    await _exit(completed: true);
  }

  Future<void> _exit({required bool completed}) async {
    if (_exiting) return;
    _exiting = true;
    _finishTimer?.cancel();
    _pipeline.removeListener(_refresh);
    if (!completed) {
      await _pipeline.close();
      await _cues.close();
      if (mounted) Navigator.of(context).pop(false);
      return;
    }
    await finishGuidedDemoTransition(
      closeCamera: () async {
        await _pipeline.close();
        await _cues.close();
      },
      persistVisit: () async {
        try {
          await ref
              .read(historyStorageProvider)
              .markDemoVisited(widget.exercise.name);
        } catch (_) {
          // Demo completion must never block normal exercise setup.
        }
      },
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _openSettings() async {
    try {
      await _settingsChannel.invokeMethod<void>('open');
    } on PlatformException {
      // Camera retry remains available.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cues.interrupt();
      unawaited(_pipeline.pause());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_pipeline.start());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _finishTimer?.cancel();
    if (!_exiting) {
      _pipeline.removeListener(_refresh);
      unawaited(_pipeline.close());
      unawaited(_cues.close());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = const ExerciseRegistry()
        .profileFor(widget.exercise)
        .displayName;
    final waiting = switch (_status) {
      PosePipelineStatus.noPerson => 'Step into frame to continue',
      PosePipelineStatus.lowConfidence =>
        'Show the required joints to continue',
      PosePipelineStatus.initializing => 'Starting camera',
      PosePipelineStatus.failed => 'Camera needs attention',
      PosePipelineStatus.ready => null,
    };
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            PoseCameraSurface(
              pipeline: _pipeline,
              onSwitchCamera: _pipeline.switchCamera,
              onRetry: _pipeline.retry,
              onOpenSettings: _openSettings,
            ),
            Align(
              alignment: Alignment.topLeft,
              child: IconButton.filledTonal(
                key: const Key('close_guided_demo'),
                tooltip: 'Exit demo',
                onPressed: () => _exit(completed: false),
                icon: const Icon(Icons.close),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 720,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.55,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '$name guided setup',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          'Practice reps ${_tracker.completedReps} of '
                          '${_tracker.targetReps}',
                          key: const Key('guided_demo_progress'),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            waiting ?? _instruction,
                            key: const Key('guided_demo_instruction'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (!_tracker.isComplete) ...[
                          const SizedBox(height: AppSpacing.small),
                          const Text(
                            'Copy the guided movement. A rep counts after you '
                            'complete the full movement and return to the '
                            'starting position.',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
