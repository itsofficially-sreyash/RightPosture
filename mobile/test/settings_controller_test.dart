import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/settings_controller.dart';

void main() {
  test('settings default on and persist independent changes', () async {
    final storage = FakeSettingsStorage();
    final container = ProviderContainer(
      overrides: [settingsStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);

    expect(container.read(settingsControllerProvider).ttsEnabled, isTrue);
    expect(container.read(settingsControllerProvider).hapticsEnabled, isTrue);

    final controller = container.read(settingsControllerProvider.notifier);
    controller.setTtsEnabled(false);
    controller.setHapticsEnabled(false);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(settingsControllerProvider).ttsEnabled, isFalse);
    expect(container.read(settingsControllerProvider).hapticsEnabled, isFalse);
    expect(storage.tts, isFalse);
    expect(storage.haptics, isFalse);
  });

  test('loaded persisted values replace defaults', () {
    final container = ProviderContainer(
      overrides: [
        initialCoachingPreferencesProvider.overrideWithValue(
          const CoachingPreferences(ttsEnabled: false, hapticsEnabled: false),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(settingsControllerProvider).ttsEnabled, isFalse);
    expect(container.read(settingsControllerProvider).hapticsEnabled, isFalse);
  });
}

class FakeSettingsStorage implements SettingsStorage {
  bool? tts;
  bool? haptics;

  @override
  Future<CoachingPreferences> load() async => const CoachingPreferences();

  @override
  Future<void> saveHaptics(bool value) async => haptics = value;

  @override
  Future<void> saveTts(bool value) async => tts = value;
}
