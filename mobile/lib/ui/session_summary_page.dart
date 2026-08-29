import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../coaching_cues.dart';
import '../domain/checkpoint_tts.dart';
import '../domain/models.dart';
import '../domain/feedback_catalog.dart';
import '../domain/exercise_registry.dart';
import '../session_controller.dart';
import '../settings_controller.dart';
import 'app_theme.dart';

class SessionSummaryPage extends ConsumerStatefulWidget {
  const SessionSummaryPage({super.key});

  @override
  ConsumerState<SessionSummaryPage> createState() => _SessionSummaryPageState();
}

class _SessionSummaryPageState extends ConsumerState<SessionSummaryPage> {
  late final CoachingCueCoordinator _cues;

  @override
  void initState() {
    super.initState();
    _cues = CoachingCueCoordinator.production();
    final preferences = ref.read(settingsControllerProvider);
    if (preferences.ttsEnabled) unawaited(_cues.prepare());
    final session = ref.read(sessionControllerProvider);
    final summary = session.summary;
    if (summary != null) {
      _cues.speak(
        postSetCheckpointMessage(
          session.selectedExercise,
          summary,
          session.reps,
        ),
        enabled: preferences.ttsEnabled,
      );
    }
  }

  @override
  void dispose() {
    unawaited(_cues.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sessionControllerProvider);
    return SessionSummaryView(
      state: state,
      onRestart: ref.read(sessionControllerProvider.notifier).nextSet,
      onChangeExercise: ref
          .read(sessionControllerProvider.notifier)
          .changeExercise,
      onFinishWorkout: ref
          .read(sessionControllerProvider.notifier)
          .finishWorkout,
    );
  }
}

class SessionSummaryView extends StatelessWidget {
  const SessionSummaryView({
    super.key,
    required this.state,
    required this.onRestart,
    this.onChangeExercise,
    this.onFinishWorkout,
  });

  final SessionState state;
  final VoidCallback onRestart;
  final VoidCallback? onChangeExercise;
  final VoidCallback? onFinishWorkout;

  @override
  Widget build(BuildContext context) {
    final summary = state.summary;
    final degraded = summary?.degradationStartRep != null;
    final score = summary?.formScorePercent;
    final exerciseName = const ExerciseRegistry()
        .profileFor(state.selectedExercise)
        .displayName;
    final setNumber = state.workout.completedSets.length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: AppColors.surfaceGlass,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'RIGHT POSTURE',
          style: TextStyle(
            color: AppColors.lime,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  sliver: SliverList.list(
                    children: [
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              border: Border.all(
                                color: AppColors.success.withValues(
                                  alpha: 0.35,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.success,
                                    size: 18,
                                  ),
                                  SizedBox(width: AppSpacing.small),
                                  Text(
                                    'SET COMPLETE',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      Semantics(
                        header: true,
                        child: Text(
                          exerciseName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        setNumber == 0
                            ? 'Post-set review'
                            : 'Set $setNumber completed',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      _PrimaryMetrics(
                        reps: summary?.totalReps ?? 0,
                        score: score,
                      ),
                      if (degraded) ...[
                        const SizedBox(height: AppSpacing.medium),
                        _SummaryCallout(summary: summary!),
                      ],
                      if (summary != null) ...[
                        const SizedBox(height: AppSpacing.large),
                        _QualityDistribution(summary: summary),
                        const SizedBox(height: AppSpacing.large),
                        _ScoreBreakdown(summary: summary),
                        const SizedBox(height: AppSpacing.large),
                        _RepTimeline(reps: state.reps),
                      ],
                      const SizedBox(height: AppSpacing.large),
                      Text(
                        'Rep checklist',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      if (state.reps.isEmpty)
                        const _EmptyChecklist()
                      else
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.medium),
                            child: Column(
                              children: [
                                for (final rep in state.reps) _RepRow(rep: rep),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.extraLarge),
                      // Weight, set targets, and timed rest require user input
                      // and stored workout fields. Keep those mockup controls
                      // out until the app can preserve their real values.
                      FilledButton(
                        key: const Key('next_set'),
                        onPressed: onRestart,
                        child: const Text('START NEXT SET'),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      OutlinedButton(
                        key: const Key('change_exercise'),
                        onPressed: onChangeExercise ?? onRestart,
                        child: const Text('CHANGE EXERCISE'),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      OutlinedButton(
                        key: const Key('finish_workout'),
                        onPressed: onFinishWorkout ?? onRestart,
                        child: const Text('FINISH WORKOUT'),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryMetrics extends StatelessWidget {
  const _PrimaryMetrics({required this.reps, required this.score});

  final int reps;
  final double? score;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cards = [
          _HeroMetric(
            semanticsLabel: '$reps reps completed',
            label: 'REPS COMPLETED',
            value: '$reps',
            accent: AppColors.lime,
          ),
          _HeroMetric(
            semanticsLabel: score == null
                ? 'Form score unavailable. Not enough data.'
                : 'Form score ${score!.round()} percent',
            label: 'FORM SCORE',
            value: score == null ? 'Not enough data' : '${score!.round()}%',
            accent: score == null ? AppColors.textMuted : _scoreColor(score!),
          ),
        ];
        if (constraints.maxWidth < 420) {
          return Column(
            children: [
              cards.first,
              const SizedBox(height: AppSpacing.medium),
              cards.last,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: cards.first),
            const SizedBox(width: AppSpacing.medium),
            Expanded(child: cards.last),
          ],
        );
      },
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.semanticsLabel,
    required this.label,
    required this.value,
    required this.accent,
  });

  final String semanticsLabel;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 176),
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            border: Border.all(color: AppColors.outlineVariant),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: accent,
                    fontSize: 76,
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

Color _scoreColor(double score) => switch (score) {
  >= 80 => AppColors.success,
  >= 60 => AppColors.warning,
  _ => AppColors.degraded,
};

class _QualityDistribution extends StatelessWidget {
  const _QualityDistribution({required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    final evaluated =
        summary.goodRepCount +
        summary.warningRepCount +
        summary.degradedRepCount;
    String quality(int count, String label) => evaluated == 0
        ? '$count $label'
        : '$count $label (${(count / evaluated * 100).round()}%)';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.small,
          children: [
            Text(quality(summary.goodRepCount, 'good')),
            Text(quality(summary.warningRepCount, 'warning')),
            Text(quality(summary.degradedRepCount, 'degraded')),
            Text('${summary.calibrationRepCount} calibration'),
          ],
        ),
      ),
    );
  }
}

class _ScoreBreakdown extends StatelessWidget {
  const _ScoreBreakdown({required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Score breakdown', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final component in summary.componentScores)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${component.label}: '
                      '${component.percent == null ? 'Unavailable' : '${component.percent!.round()}%'}',
                    ),
                  ),
                if (summary.consistencyScorePercent != null)
                  Text(
                    'Consistency score: '
                    '${summary.consistencyScorePercent!.round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                if (summary.averageTempoSeconds != null)
                  Text(
                    'Average tempo: '
                    '${summary.averageTempoSeconds!.toStringAsFixed(1)} s',
                  ),
                if (summary.averageReturnSeconds != null)
                  Text(
                    'Average return: '
                    '${summary.averageReturnSeconds!.toStringAsFixed(1)} s',
                  ),
                if (summary.averageConfidencePercent != null)
                  Text(
                    'Average confidence: '
                    '${summary.averageConfidencePercent!.round()}%',
                  ),
                if (summary.averageSymmetrySeconds != null)
                  Text(
                    'Average arm timing difference: '
                    '${summary.averageSymmetrySeconds!.toStringAsFixed(2)} s',
                  ),
                if (summary.bestRepNumber != null)
                  Text(
                    'Best rep: ${summary.bestRepNumber} · '
                    'Lowest rep: ${summary.lowestRepNumber}',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RepTimeline extends StatelessWidget {
  const _RepTimeline({required this.reps});

  final List<Rep> reps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rep timeline', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.small),
        if (reps.isEmpty)
          const Text('No reps recorded.')
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final rep in reps)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.small),
                    child: _RepMarker(rep: rep),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RepMarker extends StatelessWidget {
  const _RepMarker({required this.rep});

  final Rep rep;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (rep.status) {
      RepStatus.calibrating => (AppColors.textMuted, 'calibration'),
      RepStatus.good => (AppColors.lime, 'good'),
      RepStatus.warning => (AppColors.warning, 'warning'),
      RepStatus.degraded => (AppColors.degraded, 'degraded'),
    };
    return Semantics(
      button: true,
      label: 'Rep ${rep.number}, $label',
      child: ExcludeSemantics(
        child: IconButton.filled(
          key: Key('rep_timeline_${rep.number}'),
          tooltip: 'Rep ${rep.number}: $label',
          style: IconButton.styleFrom(backgroundColor: color),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (_) => _RepDetails(rep: rep),
          ),
          icon: Text('${rep.number}'),
        ),
      ),
    );
  }
}

class _RepDetails extends StatelessWidget {
  const _RepDetails({required this.rep});

  final Rep rep;

  @override
  Widget build(BuildContext context) {
    final metrics = rep.metrics;
    final feedback = feedbackForRep(rep);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rep ${rep.number}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(feedback ?? 'No form issue detected.'),
            if (metrics == null)
              const Text('Movement metrics unavailable.')
            else ...[
              Text(
                'Tempo: ${(metrics.totalDuration.inMilliseconds / 1000).toStringAsFixed(1)} s',
              ),
              Text(
                'Return: ${(metrics.returnDuration.inMilliseconds / 1000).toStringAsFixed(1)} s',
              ),
              Text(
                'Confidence: ${(metrics.completionConfidence * 100).round()}%',
              ),
              for (final range in metrics.rangeOfMotion.entries)
                Text(
                  '${metricLabel(range.key)}: ${range.value.toStringAsFixed(1)}°',
                ),
              if (metrics.bilateralTimingDifference != null)
                Text(
                  'Arm timing difference: '
                  '${(metrics.bilateralTimingDifference!.inMilliseconds / 1000).toStringAsFixed(2)} s',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCallout extends StatelessWidget {
  const _SummaryCallout({required this.summary});

  final SessionSummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.insights, color: AppColors.warning),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Text(
                'Form degradation detected from rep '
                '${summary.degradationStartRep}. '
                'Primary movement change: '
                '${summary.primaryResponsibleJoint ?? 'unknown joint'}.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RepRow extends StatelessWidget {
  const _RepRow({required this.rep});

  final Rep rep;

  @override
  Widget build(BuildContext context) {
    final feedback = feedbackForRep(rep);
    final (icon, color, label) = switch (rep.status) {
      RepStatus.calibrating => (Icons.tune, AppColors.textMuted, 'calibrating'),
      RepStatus.good => (Icons.check_circle, AppColors.lime, 'good'),
      RepStatus.warning => (Icons.warning_amber, AppColors.warning, 'warning'),
      RepStatus.degraded => (Icons.cancel, AppColors.degraded, 'degraded'),
    };
    return Semantics(
      label:
          'Rep ${rep.number}, $label${feedback == null ? '' : ', $feedback'}',
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.small),
              Expanded(child: Text('Rep ${rep.number} · $label')),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChecklist extends StatelessWidget {
  const _EmptyChecklist();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Text('Complete at least one rep to see feedback.'),
      ),
    );
  }
}
