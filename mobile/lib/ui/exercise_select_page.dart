import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/exercise.dart';
import '../history_storage.dart';
import '../session_controller.dart';
import 'app_theme.dart';
import 'settings_page.dart';
import 'analytics_page.dart';
import 'guided_demo_page.dart';

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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.large),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      key: const Key('open_analytics'),
                      tooltip: 'History and analytics',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AnalyticsPage(),
                        ),
                      ),
                      icon: const Icon(Icons.insights),
                    ),
                    IconButton(
                      key: const Key('open_settings'),
                      tooltip: 'Coaching settings',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsPage(),
                        ),
                      ),
                      icon: const Icon(Icons.settings),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.extraLarge),
                Text(
                  'RIGHT POSTURE',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Choose your exercise',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Get live rep counting and form-degradation feedback.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.extraLarge),
                Semantics(
                  button: true,
                  label: 'Start squat session',
                  child: Card(
                    child: ListTile(
                      key: const Key('select_squat'),
                      contentPadding: const EdgeInsets.all(AppSpacing.large),
                      leading: const DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Icon(
                            Icons.accessibility_new,
                            color: AppColors.lime,
                            size: 32,
                          ),
                        ),
                      ),
                      title: const Text('Squat'),
                      subtitle: const Text('Camera-guided form tracking'),
                      trailing: _ExerciseActions(
                        exercise: ExerciseId.squat,
                        ref: ref,
                      ),
                      onTap: () => openExercise(context, ref, ExerciseId.squat),
                    ),
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: AppSpacing.medium),
                  Semantics(
                    button: true,
                    label: 'Start bicep curl test session',
                    child: Card(
                      child: ListTile(
                        key: const Key('select_bicep_curl'),
                        contentPadding: const EdgeInsets.all(AppSpacing.medium),
                        leading: const Icon(
                          Icons.fitness_center,
                          color: AppColors.lime,
                        ),
                        title: const Text('Bicep Curl'),
                        subtitle: const Text('Device tuning preview'),
                        trailing: _ExerciseActions(
                          exercise: ExerciseId.bicepCurl,
                          ref: ref,
                        ),
                        onTap: () =>
                            openExercise(context, ref, ExerciseId.bicepCurl),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Semantics(
                    button: true,
                    label: 'Start lateral raise test session',
                    child: Card(
                      child: ListTile(
                        key: const Key('select_lateral_raise'),
                        contentPadding: const EdgeInsets.all(AppSpacing.medium),
                        leading: const Icon(
                          Icons.accessibility_new,
                          color: AppColors.lime,
                        ),
                        title: const Text('Lateral Raise'),
                        subtitle: const Text('Device tuning preview'),
                        trailing: _ExerciseActions(
                          exercise: ExerciseId.lateralRaise,
                          ref: ref,
                        ),
                        onTap: () =>
                            openExercise(context, ref, ExerciseId.lateralRaise),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Semantics(
                    button: true,
                    label: 'Start shoulder press test session',
                    child: Card(
                      child: ListTile(
                        key: const Key('select_shoulder_press'),
                        contentPadding: const EdgeInsets.all(AppSpacing.medium),
                        leading: const Icon(
                          Icons.fitness_center,
                          color: AppColors.lime,
                        ),
                        title: const Text('Shoulder Press'),
                        subtitle: const Text('Device tuning preview'),
                        trailing: _ExerciseActions(
                          exercise: ExerciseId.shoulderPress,
                          ref: ref,
                        ),
                        onTap: () => openExercise(
                          context,
                          ref,
                          ExerciseId.shoulderPress,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.extraLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseActions extends StatelessWidget {
  const _ExerciseActions({required this.exercise, required this.ref});

  final ExerciseId exercise;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: Key('replay_${exercise.name}_demo'),
          tooltip: 'Replay guided demo',
          onPressed: () =>
              openExercise(context, ref, exercise, replayDemo: true),
          icon: const Icon(Icons.school_outlined),
        ),
        const Icon(Icons.arrow_forward, color: AppColors.lime),
      ],
    );
  }
}
