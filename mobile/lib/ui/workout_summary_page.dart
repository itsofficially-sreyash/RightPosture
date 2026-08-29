import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/exercise.dart';
import '../domain/exercise_registry.dart';
import '../domain/workout.dart';
import '../session_controller.dart';
import 'app_theme.dart';

class WorkoutSummaryPage extends ConsumerWidget {
  const WorkoutSummaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(
      sessionControllerProvider.select((state) => state.workout),
    );
    return WorkoutSummaryView(
      workout: workout,
      onNewWorkout: ref.read(sessionControllerProvider.notifier).reset,
    );
  }
}

class WorkoutSummaryView extends StatelessWidget {
  const WorkoutSummaryView({
    super.key,
    required this.workout,
    required this.onNewWorkout,
  });

  final WorkoutState workout;
  final VoidCallback onNewWorkout;

  @override
  Widget build(BuildContext context) {
    final grouped = <ExerciseId, List<CompletedSet>>{};
    for (final set in workout.completedSets) {
      grouped.putIfAbsent(set.exercise, () => []).add(set);
    }
    final totalReps = workout.completedSets.fold<int>(
      0,
      (sum, set) => sum + set.summary.totalReps,
    );
    final scores = workout.completedSets
        .map((set) => set.summary.formScorePercent)
        .whereType<double>()
        .toList(growable: false);
    final averageForm = scores.isEmpty
        ? null
        : scores.reduce((a, b) => a + b) / scores.length;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.surfaceGlass,
        foregroundColor: AppColors.lime,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'RIGHT POSTURE',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 896),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Workout Complete',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          '${workout.completedSets.length} sets · $totalReps reps',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.large),
                        _WorkoutOverview(
                          sets: workout.completedSets.length,
                          reps: totalReps,
                          exercises: grouped.length,
                          averageForm: averageForm,
                        ),
                        const SizedBox(height: AppSpacing.extraLarge),
                        Text(
                          'Exercise Breakdown',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        if (grouped.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.medium),
                              child: Text('No completed sets.'),
                            ),
                          )
                        else
                          for (final entry in grouped.entries)
                            _ExerciseSets(
                              exercise: entry.key,
                              sets: entry.value,
                            ),
                        const SizedBox(height: AppSpacing.large),
                        FilledButton(
                          key: const Key('new_workout'),
                          onPressed: onNewWorkout,
                          child: const Text('START NEW WORKOUT'),
                        ),
                        const SizedBox(height: AppSpacing.extraLarge),
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

class _WorkoutOverview extends StatelessWidget {
  const _WorkoutOverview({
    required this.sets,
    required this.reps,
    required this.exercises,
    required this.averageForm,
  });

  final int sets;
  final int reps;
  final int exercises;
  final double? averageForm;

  @override
  Widget build(BuildContext context) {
    // Duration, lifted volume, weight, and RPE require user input and stored
    // model fields. Never manufacture those values from pose-tracking data.
    final stats = [
      ('TOTAL SETS', '$sets', AppColors.lime),
      ('TOTAL REPS', '$reps', AppColors.lime),
      ('EXERCISES', '$exercises', AppColors.cyan),
      (
        'AVG FORM',
        averageForm == null ? '—' : '${averageForm!.round()}%',
        averageForm == null ? AppColors.textMuted : _scoreColor(averageForm!),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 4 : 2;
        final width =
            (constraints.maxWidth - AppSpacing.small * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            for (final (label, value, color) in stats)
              SizedBox(
                width: width,
                child: _SummaryStat(label: label, value: value, color: color),
              ),
          ],
        );
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseSets extends StatelessWidget {
  const _ExerciseSets({required this.exercise, required this.sets});

  final ExerciseId exercise;
  final List<CompletedSet> sets;

  @override
  Widget build(BuildContext context) {
    final name = const ExerciseRegistry().profileFor(exercise).displayName;
    final scores = sets
        .map((set) => set.summary.formScorePercent)
        .whereType<double>()
        .toList(growable: false);
    final averageScore = scores.isEmpty
        ? null
        : scores.reduce((a, b) => a + b) / scores.length;
    final color = averageScore == null
        ? AppColors.textMuted
        : _scoreColor(averageScore);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Icon(
                averageScore != null && averageScore >= 90
                    ? Icons.check_circle
                    : Icons.warning_amber,
                color: color,
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                averageScore == null
                    ? 'FORM: —'
                    : 'FORM: ${averageScore.round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          for (final (index, set) in sets.indexed)
            _SetCard(set: set, previous: index == 0 ? null : sets[index - 1]),
        ],
      ),
    );
  }
}

class _SetCard extends StatelessWidget {
  const _SetCard({required this.set, required this.previous});

  final CompletedSet set;
  final CompletedSet? previous;

  @override
  Widget build(BuildContext context) {
    final summary = set.summary;
    final range = _averagePrimaryRange(set);
    final score = summary.formScorePercent;
    final accent = score == null ? AppColors.textMuted : _scoreColor(score);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: AppSpacing.base,
              height: 72,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.large,
                    runSpacing: AppSpacing.small,
                    children: [
                      _SetMetric(label: 'SET', value: '${set.setNumber}'),
                      _SetMetric(label: 'REPS', value: '${summary.totalReps}'),
                      _SetMetric(
                        label: 'AVG TEMPO',
                        value: summary.averageTempoSeconds == null
                            ? '—'
                            : '${summary.averageTempoSeconds!.toStringAsFixed(1)} s',
                      ),
                      _SetMetric(
                        label: 'FORM',
                        value: score == null ? '—' : '${score.round()}%',
                        color: accent,
                      ),
                      _SetMetric(
                        label: 'AVG RANGE',
                        value: range == null
                            ? '—'
                            : '${range.toStringAsFixed(1)}°',
                      ),
                    ],
                  ),
                  if (summary.degradationStartRep != null) ...[
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      'Form changed from rep ${summary.degradationStartRep}',
                      style: const TextStyle(color: AppColors.warning),
                    ),
                  ],
                  if (previous != null) ...[
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      _comparison(previous!, set),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetMetric extends StatelessWidget {
  const _SetMetric({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.base),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

double? _averagePrimaryRange(CompletedSet set) {
  final values = set.reps
      .map((rep) => rep.metrics?.rangeOfMotion.values)
      .whereType<Iterable<double>>()
      .where((range) => range.isNotEmpty)
      .map((range) => range.reduce((a, b) => a + b) / range.length)
      .toList(growable: false);
  return values.isEmpty ? null : values.reduce((a, b) => a + b) / values.length;
}

String _comparison(CompletedSet previous, CompletedSet current) {
  final previousScore = previous.summary.formScorePercent;
  final currentScore = current.summary.formScorePercent;
  if (previousScore == null || currentScore == null) {
    return 'Not enough comparable Form Score data.';
  }
  final difference = currentScore - previousScore;
  if (difference.abs() < 2) return 'Form Score remained stable.';
  return difference > 0
      ? 'Form Score improved by ${difference.round()} points.'
      : 'Form Score decreased by ${difference.abs().round()} points.';
}

Color _scoreColor(double score) => switch (score) {
  >= 90 => AppColors.success,
  >= 70 => AppColors.warning,
  _ => AppColors.degraded,
};
