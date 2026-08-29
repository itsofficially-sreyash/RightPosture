import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/exercise.dart';
import '../history_storage.dart';
import '../session_controller.dart';
import 'analytics_page.dart';
import 'app_theme.dart';
import 'guided_demo_page.dart';
import 'settings_page.dart';

Future<void> openExercise(
  BuildContext context,
  WidgetRef ref,
  ExerciseId exercise, {
  bool replayDemo = false,
}) async {
  final visits = await ref.read(historyStorageProvider).loadDemoVisits();
  if (!context.mounted) return;
  if (replayDemo || !visits.contains(exercise.name)) {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => GuidedDemoPage(exercise: exercise),
      ),
    );
    if (!context.mounted || completed != true) return;
  }
  ref
      .read(sessionControllerProvider.notifier)
      .prepareSession(exercise: exercise);
}

class ExerciseSelectPage extends ConsumerWidget {
  const ExerciseSelectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: AppColors.surfaceGlass,
        foregroundColor: AppColors.lime,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: const Text(
          'RIGHT POSTURE',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            key: const Key('open_profile'),
            tooltip: 'Coaching settings',
            onPressed: () => _openSettings(context),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          const SizedBox(width: AppSpacing.small),
        ],
      ),
      bottomNavigationBar: _BottomNavigation(
        onWorkout: () {},
        onAnalytics: () => _openAnalytics(context),
        onSettings: () => _openSettings(context),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 600
                ? AppSpacing.extraLarge
                : AppSpacing.medium + AppSpacing.base;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.extraLarge,
                horizontalPadding,
                AppSpacing.extraLarge,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 896),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose your exercise',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          'Select an exercise to begin analysis. Ensure your camera is positioned correctly.',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Wrap(
                          spacing: AppSpacing.small,
                          runSpacing: AppSpacing.small,
                          children: [
                            OutlinedButton.icon(
                              key: const Key('open_settings'),
                              onPressed: () => _openSettings(context),
                              icon: const Icon(Icons.tune),
                              label: const Text('COACH SETTINGS'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.extraLarge),
                        _ExerciseGrid(ref: ref),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openAnalytics(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AnalyticsPage()));
  }

  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
  }
}

class _ExerciseGrid extends StatelessWidget {
  const _ExerciseGrid({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final exercises = <_ExerciseCardData>[
      const _ExerciseCardData(
        id: ExerciseId.squat,
        keyName: 'select_squat',
        title: 'Squat',
        description: 'Lower-body power and form tracking',
        icon: Icons.accessibility_new,
        status: 'CAMERA GUIDED',
        accent: AppColors.success,
      ),
      if (kDebugMode) ...[
        const _ExerciseCardData(
          id: ExerciseId.bicepCurl,
          keyName: 'select_bicep_curl',
          title: 'Bicep Curl',
          description: 'Elbow control and curl alignment',
          icon: Icons.fitness_center,
          status: 'TUNING PREVIEW',
          accent: AppColors.warning,
        ),
        const _ExerciseCardData(
          id: ExerciseId.lateralRaise,
          keyName: 'select_lateral_raise',
          title: 'Lateral Raise',
          description: 'Shoulder symmetry and movement control',
          icon: Icons.accessibility_new,
          status: 'TUNING PREVIEW',
          accent: AppColors.cyan,
        ),
        const _ExerciseCardData(
          id: ExerciseId.shoulderPress,
          keyName: 'select_shoulder_press',
          title: 'Shoulder Press',
          description: 'Shoulder stability and vertical path',
          icon: Icons.fitness_center,
          status: 'TUNING PREVIEW',
          accent: AppColors.success,
        ),
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 2 : 1;
        final cardWidth = columns == 2
            ? (constraints.maxWidth - AppSpacing.medium) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: [
            for (final exercise in exercises)
              SizedBox(
                width: cardWidth,
                child: _ExerciseCard(data: exercise, ref: ref),
              ),
          ],
        );
      },
    );
  }
}

class _ExerciseCardData {
  const _ExerciseCardData({
    required this.id,
    required this.keyName,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    required this.accent,
  });

  final ExerciseId id;
  final String keyName;
  final String title;
  final String description;
  final IconData icon;
  final String status;
  final Color accent;
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.data, required this.ref});

  final _ExerciseCardData data;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    // The HTML uses hosted athlete photography. Keep the app offline-safe until
    // final licensed artwork is supplied; this tonal treatment preserves the UI.
    return Semantics(
      button: true,
      label: 'Start ${data.title} session',
      child: Material(
        color: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: const BorderSide(color: AppColors.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key(data.keyName),
          onTap: () => openExercise(context, ref, data.id),
          child: Container(
            constraints: const BoxConstraints(minHeight: 188),
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.accent.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(data.icon, color: data.accent),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: AppSpacing.base,
                      height: 48,
                      decoration: BoxDecoration(
                        color: data.accent,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(data.title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.base),
                Text(
                  data.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.medium),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _StatusChip(label: data.status),
                ),
                const SizedBox(height: AppSpacing.small),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        key: Key('replay_${data.id.name}_demo'),
                        onPressed: () => openExercise(
                          context,
                          ref,
                          data.id,
                          replayDemo: true,
                        ),
                        child: const Text('DEMO'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => openExercise(context, ref, data.id),
                        child: const Text('START'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.base,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.small),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: AppColors.cyan,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _BottomNavigation extends StatelessWidget {
  const _BottomNavigation({
    required this.onWorkout,
    required this.onAnalytics,
    required this.onSettings,
  });

  final VoidCallback onWorkout;
  final VoidCallback onAnalytics;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) => switch (index) {
        0 => onWorkout(),
        1 => onAnalytics(),
        _ => onSettings(),
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.fitness_center_outlined),
          selectedIcon: Icon(Icons.fitness_center),
          label: 'Workout',
        ),
        NavigationDestination(
          icon: Icon(Icons.query_stats),
          label: 'Analytics',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    );
  }
}
