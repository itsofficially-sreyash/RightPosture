import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/analytics.dart';
import '../domain/analytics_insights.dart';
import '../domain/exercise.dart';
import '../domain/exercise_registry.dart';
import '../domain/feedback_catalog.dart';
import '../domain/history.dart';
import '../domain/models.dart';
import '../history_storage.dart';
import 'app_theme.dart';

final historyProvider = FutureProvider<List<HistoryWorkout>>(
  (ref) => ref.read(historyStorageProvider).load(),
);

class AnalyticsPage extends ConsumerStatefulWidget {
  const AnalyticsPage({super.key});

  @override
  ConsumerState<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends ConsumerState<AnalyticsPage> {
  ExerciseId _exercise = ExerciseId.squat;
  String? _selectedDay;

  static const _exercises = [
    ExerciseId.squat,
    ExerciseId.bicepCurl,
    ExerciseId.lateralRaise,
    ExerciseId.shoulderPress,
  ];

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SafeArea(
        child: history.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              _StorageError(onRetry: () => ref.invalidate(historyProvider)),
          data: (workouts) => _AnalyticsContent(
            workouts: workouts,
            exercise: _exercise,
            selectedDay: _selectedDay,
            onExerciseChanged: (value) => setState(() {
              _exercise = value;
              _selectedDay = null;
            }),
            onDaySelected: (value) => setState(() => _selectedDay = value),
            onHistoryChanged: () => ref.invalidate(historyProvider),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  const _AnalyticsContent({
    required this.workouts,
    required this.exercise,
    required this.selectedDay,
    required this.onExerciseChanged,
    required this.onDaySelected,
    required this.onHistoryChanged,
  });

  final List<HistoryWorkout> workouts;
  final ExerciseId exercise;
  final String? selectedDay;
  final ValueChanged<ExerciseId> onExerciseChanged;
  final ValueChanged<String?> onDaySelected;
  final VoidCallback onHistoryChanged;

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) {
      return const _EmptyAnalytics();
    }
    final profile = const ExerciseRegistry().profileFor(exercise);
    final days = groupHistoryByLocalDay(workouts);
    final selectedWorkouts = selectedDay == null
        ? const <HistoryWorkout>[]
        : days[selectedDay] ?? const [];
    final week = weeklySummary(workouts, exercise, now: DateTime.now());
    final progress = progressInsights(workouts, exercise);
    final setRecord = bestSet(workouts, exercise);
    final sessionRecord = bestSession(workouts, exercise);
    final records = personalRecords(workouts, exercise);
    final feedback = feedbackInsights(workouts, exercise);
    final ranking = weeklyExerciseRanking(workouts, now: DateTime.now());
    final streak = latestActivityStreak(workouts);
    void openEvidence(DateTime timestamp) {
      HistoryWorkout? match;
      for (final workout in workouts) {
        if (workout.completedAt == timestamp ||
            workout.sets.any((set) => set.completedAt == timestamp)) {
          match = workout;
          break;
        }
      }
      if (match == null) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SessionHistoryPage(workout: match!),
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.large),
          sliver: SliverList.list(
            children: [
              DropdownButtonFormField<ExerciseId>(
                key: const Key('analytics_exercise_filter'),
                initialValue: exercise,
                decoration: const InputDecoration(labelText: 'Exercise'),
                items: _AnalyticsPageState._exercises
                    .map(
                      (id) => DropdownMenuItem(
                        value: id,
                        child: Text(
                          const ExerciseRegistry().profileFor(id).displayName,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) onExerciseChanged(value);
                },
              ),
              const SizedBox(height: AppSpacing.large),
              Text(
                '${profile.displayName} history',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.medium),
              _WeeklyCard(summary: week, ranking: ranking, streak: streak),
              const SizedBox(height: AppSpacing.medium),
              _ProgressInsightsCard(
                insights: progress,
                onOpenEvidence: openEvidence,
              ),
              const SizedBox(height: AppSpacing.medium),
              _RecordsCard(
                bestSetResult: setRecord,
                bestSessionResult: sessionRecord,
                records: records,
                onOpenEvidence: openEvidence,
              ),
              const SizedBox(height: AppSpacing.medium),
              _FeedbackInsightsCard(
                insights: feedback,
                onOpenEvidence: openEvidence,
              ),
              const SizedBox(height: AppSpacing.large),
              _ActivityCalendar(
                days: days,
                selectedDay: selectedDay,
                onSelected: onDaySelected,
              ),
              if (selectedDay != null) ...[
                const SizedBox(height: AppSpacing.medium),
                _DayJournal(
                  day: selectedDay!,
                  workouts: selectedWorkouts,
                  onHistoryChanged: onHistoryChanged,
                ),
              ],
              const SizedBox(height: AppSpacing.large),
              for (final metric in AnalyticsMetric.values) ...[
                _TrendCard(
                  title: _metricTitle(metric),
                  unit: _metricUnit(metric),
                  points: metricSeries(workouts, exercise, metric),
                ),
                const SizedBox(height: AppSpacing.medium),
              ],
              _QualityCard(
                distribution: qualityDistribution(workouts, exercise),
              ),
              const SizedBox(height: AppSpacing.medium),
              _IssueCard(counts: issueFrequency(workouts, exercise)),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeeklyCard extends StatelessWidget {
  const _WeeklyCard({
    required this.summary,
    required this.ranking,
    required this.streak,
  });

  final WeeklyExerciseSummary summary;
  final WeeklyExerciseRanking ranking;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Wrap(
          spacing: AppSpacing.large,
          runSpacing: AppSpacing.small,
          children: [
            Text('${summary.sets} sets this week'),
            Text('${summary.reps} reps'),
            Text(
              'Average Form Score: '
              '${summary.averageFormScore == null ? 'Unavailable' : '${summary.averageFormScore!.round()}%'}',
            ),
            Text(
              'Latest activity streak: $streak day${streak == 1 ? '' : 's'}',
            ),
            if (ranking.tied)
              const Text('Weekly exercise ranking: tied')
            else if (ranking.strongest == null)
              const Text('Weekly exercise ranking needs 2 exercises')
            else
              Text(
                'Weekly strongest: ${_exerciseName(ranking.strongest!)} · '
                'needs attention: ${_exerciseName(ranking.weakest!)}',
              ),
            if (ranking.scores.isNotEmpty)
              const Text('Ranking uses available Form Score and consistency.'),
          ],
        ),
      ),
    );
  }
}

class _ProgressInsightsCard extends StatelessWidget {
  const _ProgressInsightsCard({
    required this.insights,
    required this.onOpenEvidence,
  });

  final List<MetricInsight> insights;
  final ValueChanged<DateTime> onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Recent progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (insights.isEmpty)
              const Text('At least 2 comparable sessions are required.')
            else
              for (final insight in insights) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_insightIcon(insight.direction)),
                  title: Text(
                    '${_metricTitle(insight.metric).replaceAll(' trend', '')}: '
                    '${_directionLabel(insight.direction)}',
                  ),
                  subtitle: Text(
                    '${insight.previousValue.toStringAsFixed(1)} to '
                    '${insight.currentValue.toStringAsFixed(1)} '
                    '${_metricUnit(insight.metric)}',
                  ),
                ),
                _EvidenceButtons(
                  earlier: insight.evidence.first.timestamp,
                  later: insight.evidence.last.timestamp,
                  onOpen: onOpenEvidence,
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _RecordsCard extends StatelessWidget {
  const _RecordsCard({
    required this.bestSetResult,
    required this.bestSessionResult,
    required this.records,
    required this.onOpenEvidence,
  });

  final RankedSet? bestSetResult;
  final RankedSession? bestSessionResult;
  final List<PersonalRecord> records;
  final ValueChanged<DateTime> onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Best and records',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (bestSetResult == null)
              const Text('No supported record yet.')
            else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  bestSetResult!.tied ? 'Best set: tied' : 'Best set',
                ),
                subtitle: Text(
                  '${bestSetResult!.set.formScorePercent!.round()}% Form Score · '
                  '${bestSetResult!.set.consistencyScorePercent == null ? 'Consistency unavailable' : '${bestSetResult!.set.consistencyScorePercent!.round()}% consistency'} · '
                  '${_dateLabel(bestSetResult!.set.completedAt)}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onOpenEvidence(bestSetResult!.set.completedAt),
              ),
              if (bestSessionResult != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    bestSessionResult!.tied
                        ? 'Best session: tied'
                        : 'Best session',
                  ),
                  subtitle: Text(
                    '${bestSessionResult!.formScore.round()}% Form Score · '
                    '${_dateLabel(bestSessionResult!.workout.completedAt)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () =>
                      onOpenEvidence(bestSessionResult!.workout.completedAt),
                ),
              for (final record in records)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(record.label),
                  subtitle: Text(
                    '${record.value.toStringAsFixed(1)} ${record.unit} · '
                    '${_dateLabel(record.timestamp)}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => onOpenEvidence(record.timestamp),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackInsightsCard extends StatelessWidget {
  const _FeedbackInsightsCard({
    required this.insights,
    required this.onOpenEvidence,
  });

  final List<FeedbackInsight> insights;
  final ValueChanged<DateTime> onOpenEvidence;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Feedback follow-up',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (insights.isEmpty)
              const Text('Repeated feedback needs a later comparable session.')
            else
              for (final insight in insights) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_insightIcon(insight.direction)),
                  title: Text(
                    '${insight.instruction ?? '${metricLabel(insight.metric)} feedback'}: '
                    '${_directionLabel(insight.direction)}',
                  ),
                  subtitle: Text(
                    'Issue rate ${(insight.previousRate * 100).round()}% to '
                    '${(insight.currentRate * 100).round()}% · '
                    '${_dateLabel(insight.previousTimestamp)} to '
                    '${_dateLabel(insight.currentTimestamp)}',
                  ),
                ),
                _EvidenceButtons(
                  earlier: insight.previousTimestamp,
                  later: insight.currentTimestamp,
                  onOpen: onOpenEvidence,
                ),
              ],
          ],
        ),
      ),
    );
  }
}

class _EvidenceButtons extends StatelessWidget {
  const _EvidenceButtons({
    required this.earlier,
    required this.later,
    required this.onOpen,
  });

  final DateTime earlier;
  final DateTime later;
  final ValueChanged<DateTime> onOpen;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.small,
      children: [
        TextButton(
          onPressed: () => onOpen(earlier),
          child: Text('Earlier · ${_dateLabel(earlier)}'),
        ),
        TextButton(
          onPressed: () => onOpen(later),
          child: Text('Later · ${_dateLabel(later)}'),
        ),
      ],
    );
  }
}

class _ActivityCalendar extends StatelessWidget {
  const _ActivityCalendar({
    required this.days,
    required this.selectedDay,
    required this.onSelected,
  });

  final Map<String, List<HistoryWorkout>> days;
  final String? selectedDay;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final keys = days.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity calendar',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.small),
        Wrap(
          spacing: AppSpacing.small,
          runSpacing: AppSpacing.small,
          children: [
            for (final day in keys.take(14))
              ChoiceChip(
                label: Text('$day · ${days[day]!.length}'),
                selected: selectedDay == day,
                onSelected: (selected) => onSelected(selected ? day : null),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayJournal extends StatelessWidget {
  const _DayJournal({
    required this.day,
    required this.workouts,
    required this.onHistoryChanged,
  });

  final String day;
  final List<HistoryWorkout> workouts;
  final VoidCallback onHistoryChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(day, style: Theme.of(context).textTheme.titleMedium),
            for (final workout in workouts)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${workout.sets.length} sets · '
                  '${workout.sets.fold<int>(0, (sum, set) => sum + set.totalReps)} reps',
                ),
                subtitle: Text(
                  workout.sets
                      .map(
                        (set) => const ExerciseRegistry()
                            .profileFor(set.exercise)
                            .displayName,
                      )
                      .toSet()
                      .join(', '),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SessionHistoryPage(workout: workout),
                    ),
                  );
                  onHistoryChanged();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.title,
    required this.unit,
    required this.points,
  });

  final String title;
  final String unit;
  final List<AnalyticsPoint> points;

  @override
  Widget build(BuildContext context) {
    final available = points.where((point) => point.value != null).toList();
    final semantic = available.isEmpty
        ? '$title unavailable'
        : '$title, ${available.length} values, latest '
              '${available.last.value!.toStringAsFixed(1)} $unit';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(unit),
            const SizedBox(height: AppSpacing.small),
            if (available.isEmpty)
              const Text('No recorded data for this metric.')
            else if (available.length == 1)
              Text(
                '${available.single.value!.toStringAsFixed(1)} $unit · '
                'Not enough data for a trend',
              )
            else
              Semantics(
                label: semantic,
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 180,
                    child: LineChart(
                      _lineData(points),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
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

LineChartData _lineData(List<AnalyticsPoint> points) {
  final segments = splitTrendSegments(points);
  return LineChartData(
    minX: 0,
    maxX: (points.length - 1).toDouble(),
    gridData: FlGridData(
      drawVerticalLine: false,
      horizontalInterval: 25,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: AppColors.surfaceElevated, strokeWidth: 1),
    ),
    titlesData: const FlTitlesData(
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 24, interval: 1),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(showTitles: true, reservedSize: 40),
      ),
    ),
    borderData: FlBorderData(show: false),
    lineBarsData: segments
        .map(
          (segment) => LineChartBarData(
            spots: segment,
            color: AppColors.lime,
            barWidth: 3,
            isCurved: false,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        )
        .toList(),
  );
}

List<List<FlSpot>> splitTrendSegments(List<AnalyticsPoint> points) {
  final segments = <List<FlSpot>>[];
  var current = <FlSpot>[];
  for (final (index, point) in points.indexed) {
    if (point.value == null) {
      if (current.isNotEmpty) segments.add(current);
      current = <FlSpot>[];
    } else {
      current.add(FlSpot(index.toDouble(), point.value!));
    }
  }
  if (current.isNotEmpty) segments.add(current);
  return segments;
}

class _QualityCard extends StatelessWidget {
  const _QualityCard({required this.distribution});

  final ({int good, int warning, int degraded}) distribution;

  @override
  Widget build(BuildContext context) {
    final total =
        distribution.good + distribution.warning + distribution.degraded;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Rep quality', style: Theme.of(context).textTheme.titleMedium),
            if (total == 0)
              const Text('No evaluated reps.')
            else ...[
              Semantics(
                label:
                    '${distribution.good} good, ${distribution.warning} warning, '
                    '${distribution.degraded} degraded reps',
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        centerSpaceRadius: 28,
                        sectionsSpace: 3,
                        sections: [
                          _pie(
                            distribution.good,
                            total,
                            AppColors.lime,
                            'Good',
                          ),
                          _pie(
                            distribution.warning,
                            total,
                            AppColors.warning,
                            'Warning',
                          ),
                          _pie(
                            distribution.degraded,
                            total,
                            AppColors.degraded,
                            'Degraded',
                          ),
                        ].where((section) => section.value > 0).toList(),
                      ),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                    ),
                  ),
                ),
              ),
              Text(
                '${distribution.good} good · ${distribution.warning} warning · '
                '${distribution.degraded} degraded',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

PieChartSectionData _pie(int value, int total, Color color, String label) =>
    PieChartSectionData(
      value: value.toDouble(),
      color: color,
      radius: 48,
      title: '$label\n${(value / total * 100).round()}%',
      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    );

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.counts});

  final Map<MovementMetric, int> counts;

  @override
  Widget build(BuildContext context) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Issue frequency',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (entries.isEmpty)
              const Text('No detected issues.')
            else ...[
              Semantics(
                label: entries
                    .map((entry) => '${metricLabel(entry.key)} ${entry.value}')
                    .join(', '),
                child: ExcludeSemantics(
                  child: SizedBox(
                    height: 160,
                    child: BarChart(
                      BarChartData(
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        barGroups: [
                          for (final (index, entry) in entries.take(5).indexed)
                            BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value.toDouble(),
                                  color: AppColors.warning,
                                  width: 20,
                                ),
                              ],
                            ),
                        ],
                      ),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 200),
                    ),
                  ),
                ),
              ),
              for (final entry in entries.take(5))
                Text('${metricLabel(entry.key)}: ${entry.value}'),
            ],
          ],
        ),
      ),
    );
  }
}

class SessionHistoryPage extends ConsumerStatefulWidget {
  const SessionHistoryPage({super.key, required this.workout});

  final HistoryWorkout workout;

  @override
  ConsumerState<SessionHistoryPage> createState() => _SessionHistoryPageState();
}

class _SessionHistoryPageState extends ConsumerState<SessionHistoryPage> {
  late final TextEditingController _note = TextEditingController(
    text: widget.workout.note,
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session entry')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.large),
          children: [
            Text(_dateLabel(widget.workout.completedAt)),
            const SizedBox(height: AppSpacing.medium),
            TextField(
              key: const Key('session_note'),
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Session note',
                hintText: 'Example: felt tired or used 5 kg dumbbells',
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            FilledButton(
              key: const Key('save_session_note'),
              onPressed: () async {
                await ref
                    .read(historyStorageProvider)
                    .updateNote(widget.workout.completedAt, _note.text);
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Note saved')));
              },
              child: const Text('Save note'),
            ),
            const SizedBox(height: AppSpacing.large),
            for (final (index, set) in widget.workout.sets.indexed)
              _HistorySetCard(index: index + 1, set: set),
          ],
        ),
      ),
    );
  }
}

class _HistorySetCard extends StatelessWidget {
  const _HistorySetCard({required this.index, required this.set});

  final int index;
  final HistorySet set;

  @override
  Widget build(BuildContext context) {
    final name = const ExerciseRegistry().profileFor(set.exercise).displayName;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set $index · $name',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('${set.totalReps} reps'),
            Text(
              'Form Score: ${set.formScorePercent?.round() ?? 'Unavailable'}${set.formScorePercent == null ? '' : '%'}',
            ),
            Text(
              'Average ROM: ${set.averageRange?.toStringAsFixed(1) ?? 'Unavailable'}',
            ),
            Text(
              'Average tempo: ${set.averageTempoSeconds?.toStringAsFixed(1) ?? 'Unavailable'}',
            ),
            Text(
              'Consistency: ${set.consistencyScorePercent?.round() ?? 'Unavailable'}${set.consistencyScorePercent == null ? '' : '%'}',
            ),
            const SizedBox(height: AppSpacing.small),
            const Text('Rep timeline'),
            Wrap(
              spacing: AppSpacing.small,
              children: [
                for (final rep in set.repOutcomes)
                  Semantics(
                    label: 'Rep ${rep.number}, ${rep.status.name}',
                    child: Chip(
                      avatar: Icon(_statusIcon(rep.status), size: 18),
                      label: Text('${rep.number}'),
                    ),
                  ),
              ],
            ),
            if (set.issues.isNotEmpty) ...[
              const Text('Issues'),
              for (final issue in set.issues)
                Text('${metricLabel(issue.metric)} · ${issue.direction.name}'),
            ],
            if (set.feedback.isNotEmpty) ...[
              const Text('Feedback history'),
              for (final feedback in set.feedback) Text(feedback),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyAnalytics extends StatelessWidget {
  const _EmptyAnalytics();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(AppSpacing.large),
      child: Text('Complete a workout to create movement-quality analytics.'),
    ),
  );
}

class _StorageError extends StatelessWidget {
  const _StorageError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('History could not be loaded.'),
          const SizedBox(height: AppSpacing.small),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

String _metricTitle(AnalyticsMetric metric) => switch (metric) {
  AnalyticsMetric.formScore => 'Form Score trend',
  AnalyticsMetric.rangeOfMotion => 'Range of motion trend',
  AnalyticsMetric.tempo => 'Tempo trend',
  AnalyticsMetric.degradationPoint => 'Form degradation point',
  AnalyticsMetric.symmetry => 'Left / right symmetry trend',
  AnalyticsMetric.consistency => 'Consistency trend',
};

String _metricUnit(AnalyticsMetric metric) => switch (metric) {
  AnalyticsMetric.formScore || AnalyticsMetric.consistency => 'percent',
  AnalyticsMetric.rangeOfMotion => 'degrees',
  AnalyticsMetric.tempo || AnalyticsMetric.symmetry => 'seconds',
  AnalyticsMetric.degradationPoint => 'rep number',
};

String _directionLabel(InsightDirection direction) => switch (direction) {
  InsightDirection.improved => 'improved',
  InsightDirection.declined => 'needs attention',
  InsightDirection.unchanged => 'unchanged',
};

IconData _insightIcon(InsightDirection direction) => switch (direction) {
  InsightDirection.improved => Icons.trending_up,
  InsightDirection.declined => Icons.trending_down,
  InsightDirection.unchanged => Icons.trending_flat,
};

String _exerciseName(ExerciseId exercise) =>
    const ExerciseRegistry().profileFor(exercise).displayName;

String _dateLabel(DateTime date) {
  final local = date.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}

IconData _statusIcon(RepStatus status) => switch (status) {
  RepStatus.calibrating => Icons.tune,
  RepStatus.good => Icons.check_circle,
  RepStatus.warning => Icons.warning_amber,
  RepStatus.degraded => Icons.cancel,
};
