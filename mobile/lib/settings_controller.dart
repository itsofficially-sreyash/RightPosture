import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoachingPreferences {
  const CoachingPreferences({
    this.ttsEnabled = true,
    this.hapticsEnabled = true,
  });

  final bool ttsEnabled;
  final bool hapticsEnabled;

  CoachingPreferences copyWith({bool? ttsEnabled, bool? hapticsEnabled}) =>
      CoachingPreferences(
        ttsEnabled: ttsEnabled ?? this.ttsEnabled,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      );
}

abstract interface class SettingsStorage {
  Future<CoachingPreferences> load();
  Future<void> saveTts(bool value);
  Future<void> saveHaptics(bool value);
}

class SharedPreferencesSettingsStorage implements SettingsStorage {
  SharedPreferencesSettingsStorage([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _ttsKey = 'coaching.tts';
  static const _hapticsKey = 'coaching.haptics';
  final SharedPreferencesAsync _preferences;

  @override
  Future<CoachingPreferences> load() async => CoachingPreferences(
    ttsEnabled: await _preferences.getBool(_ttsKey) ?? true,
    hapticsEnabled: await _preferences.getBool(_hapticsKey) ?? true,
  );

  @override
  Future<void> saveTts(bool value) => _preferences.setBool(_ttsKey, value);

  @override
  Future<void> saveHaptics(bool value) =>
      _preferences.setBool(_hapticsKey, value);
}

final initialCoachingPreferencesProvider = Provider<CoachingPreferences>(
  (_) => const CoachingPreferences(),
);

final settingsStorageProvider = Provider<SettingsStorage>(
  (_) => SharedPreferencesSettingsStorage(),
);

final settingsControllerProvider =
    NotifierProvider<SettingsController, CoachingPreferences>(
      SettingsController.new,
    );

class SettingsController extends Notifier<CoachingPreferences> {
  @override
  CoachingPreferences build() => ref.read(initialCoachingPreferencesProvider);

  void setTtsEnabled(bool value) {
    state = state.copyWith(ttsEnabled: value);
    unawaited(ref.read(settingsStorageProvider).saveTts(value));
  }

  void setHapticsEnabled(bool value) {
    state = state.copyWith(hapticsEnabled: value);
    unawaited(ref.read(settingsStorageProvider).saveHaptics(value));
  }
}
