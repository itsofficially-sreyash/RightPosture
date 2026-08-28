import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/exercise.dart';
import '../session_controller.dart';
import 'app_theme.dart';
import 'settings_page.dart';

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
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    key: const Key('open_settings'),
                    tooltip: 'Coaching settings',
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsPage(),
                      ),
                    ),
                    icon: const Icon(Icons.settings),
                  ),
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
                    child: InkWell(
                      key: const Key('select_squat'),
                      borderRadius: BorderRadius.circular(AppRadius.large),
                      onTap: () {
                        ref
                            .read(sessionControllerProvider.notifier)
                            .prepareSession();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(AppSpacing.large),
                        child: Row(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                shape: BoxShape.circle,
                              ),
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: Icon(
                                  Icons.accessibility_new,
                                  color: AppColors.lime,
                                  size: 34,
                                ),
                              ),
                            ),
                            SizedBox(width: AppSpacing.medium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Squat',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Camera-guided form tracking',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.arrow_forward, color: AppColors.lime),
                          ],
                        ),
                      ),
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
                        trailing: const Icon(
                          Icons.arrow_forward,
                          color: AppColors.lime,
                        ),
                        onTap: () => ref
                            .read(sessionControllerProvider.notifier)
                            .prepareSession(exercise: ExerciseId.bicepCurl),
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
                        trailing: const Icon(
                          Icons.arrow_forward,
                          color: AppColors.lime,
                        ),
                        onTap: () => ref
                            .read(sessionControllerProvider.notifier)
                            .prepareSession(exercise: ExerciseId.lateralRaise),
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
                        trailing: const Icon(
                          Icons.arrow_forward,
                          color: AppColors.lime,
                        ),
                        onTap: () => ref
                            .read(sessionControllerProvider.notifier)
                            .prepareSession(exercise: ExerciseId.shoulderPress),
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
