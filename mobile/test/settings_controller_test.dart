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
    expect(container.read(settingsControllerProvider).soundEnabled, isTrue);

    final controller = container.read(settingsControllerProvider.notifier);
    controller.setTtsEnabled(false);
    controller.setHapticsEnabled(false);
    controller.setSoundEnabled(false);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(settingsControllerProvider).ttsEnabled, isFalse);
    expect(container.read(settingsControllerProvider).hapticsEnabled, isFalse);
    expect(container.read(settingsControllerProvider).soundEnabled, isFalse);
    expect(storage.tts, isFalse);
    expect(storage.haptics, isFalse);
    expect(storage.sound, isFalse);
  });

  test('loaded persisted values replace defaults', () {
    final container = ProviderContainer(
      overrides: [
        initialCoachingPreferencesProvider.overrideWithValue(
          const CoachingPreferences(
            ttsEnabled: false,
            hapticsEnabled: false,
            soundEnabled: false,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(settingsControllerProvider).ttsEnabled, isFalse);
    expect(container.read(settingsControllerProvider).hapticsEnabled, isFalse);
    expect(container.read(settingsControllerProvider).soundEnabled, isFalse);
  });
}

class FakeSettingsStorage implements SettingsStorage {
  bool? tts;
  bool? haptics;
  bool? sound;

  @override
  Future<CoachingPreferences> load() async => const CoachingPreferences();

  @override
  Future<void> saveHaptics(bool value) async => haptics = value;

  @override
  Future<void> saveTts(bool value) async => tts = value;

  @override
  Future<void> saveSound(bool value) async => sound = value;
}
