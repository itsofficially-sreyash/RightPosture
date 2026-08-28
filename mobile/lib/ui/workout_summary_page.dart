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
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.large),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Workout complete',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    '${workout.completedSets.length} sets · '
                    '${workout.completedSets.fold<int>(0, (sum, set) => sum + set.summary.totalReps)} reps',
                  ),
                  const SizedBox(height: AppSpacing.large),
                  if (grouped.isEmpty)
                    const Text('No completed sets.')
                  else
                    for (final entry in grouped.entries)
                      _ExerciseSets(exercise: entry.key, sets: entry.value),
                  const SizedBox(height: AppSpacing.large),
                  FilledButton(
                    key: const Key('new_workout'),
                    onPressed: onNewWorkout,
                    child: const Text('New workout'),
                  ),
                ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: Theme.of(context).textTheme.titleLarge),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Set ${set.setNumber}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            Text('${summary.totalReps} reps'),
            Text(
              'Form Score: ${summary.formScorePercent == null ? 'Unavailable' : '${summary.formScorePercent!.round()}%'}',
            ),
            Text(
              'Average tempo: ${summary.averageTempoSeconds == null ? 'Unavailable' : '${summary.averageTempoSeconds!.toStringAsFixed(1)} s'}',
            ),
            Text(
              'Average range: ${range == null ? 'Unavailable' : '${range.toStringAsFixed(1)}°'}',
            ),
            Text('Degradation point: ${summary.degradationStartRep ?? 'None'}'),
            Text(
              'Consistency: ${summary.consistencyScorePercent == null ? 'Unavailable' : '${summary.consistencyScorePercent!.round()}%'}',
            ),
            Text(
              'Detected issues: ${set.reps.fold<int>(0, (sum, rep) => sum + rep.issues.length)}',
            ),
            if (previous != null) ...[
              const SizedBox(height: AppSpacing.small),
              Text(_comparison(previous!, set)),
            ],
          ],
        ),
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
