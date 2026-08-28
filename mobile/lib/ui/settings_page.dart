import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings_controller.dart';
import 'app_theme.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferences = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Coaching settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.medium),
              children: [
                SwitchListTile(
                  key: const Key('tts_setting'),
                  title: const Text('Voice coaching'),
                  subtitle: const Text(
                    'Speak live exercise instructions. Requires internet.',
                  ),
                  value: preferences.ttsEnabled,
                  onChanged: controller.setTtsEnabled,
                ),
                SwitchListTile(
                  key: const Key('haptics_setting'),
                  title: const Text('Haptic coaching'),
                  subtitle: const Text('Vibrate for rep and form feedback.'),
                  value: preferences.hapticsEnabled,
                  onChanged: controller.setHapticsEnabled,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
