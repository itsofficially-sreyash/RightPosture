import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../domain/feedback_catalog.dart';
import '../domain/exercise_registry.dart';
import '../session_controller.dart';
import 'app_theme.dart';

class SessionSummaryPage extends ConsumerWidget {
  const SessionSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    return Scaffold(
      backgroundColor: AppColors.lime,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  sliver: SliverList.list(
                    children: [
                      const SizedBox(height: AppSpacing.medium),
                      Text(
                        exerciseName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.background,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Semantics(
                        header: true,
                        child: Text(
                          degraded ? 'Set reviewed' : 'Set complete',
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(color: AppColors.background),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      Semantics(
                        label: score == null
                            ? 'Form score unavailable. Not enough data.'
                            : 'Form score ${score.round()} percent',
                        child: ExcludeSemantics(
                          child: Text(
                            score == null
                                ? 'Not enough data'
                                : '${score.round()}%',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(color: AppColors.background),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        '${summary?.totalReps ?? 0} total reps',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w700,
                        ),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.background,
                        ),
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
                      FilledButton(
                        key: const Key('next_set'),
                        onPressed: onRestart,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.background,
                          foregroundColor: AppColors.lime,
                        ),
                        child: const Text('Next set'),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      OutlinedButton(
                        key: const Key('change_exercise'),
                        onPressed: onChangeExercise ?? onRestart,
                        child: const Text('Change exercise'),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      OutlinedButton(
                        key: const Key('finish_workout'),
                        onPressed: onFinishWorkout ?? onRestart,
                        child: const Text('Finish workout'),
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
        Text(
          'Score breakdown',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.background),
        ),
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
        Text(
          'Rep timeline',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppColors.background),
        ),
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
