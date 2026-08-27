import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session_controller.dart';
import 'app_theme.dart';

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
                            .startSession();
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
                const SizedBox(height: AppSpacing.extraLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
