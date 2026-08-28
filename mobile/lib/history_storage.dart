import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'domain/history.dart';
import 'domain/workout.dart';

abstract interface class HistoryBackend {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
}

class SharedPreferencesHistoryBackend implements HistoryBackend {
  SharedPreferencesHistoryBackend([SharedPreferencesAsync? preferences])
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);
}

class HistoryStorage {
  HistoryStorage(this._backend, {this.retentionLimit = 100});

  static const key = 'history.v1';
  static const version = 1;
  final HistoryBackend _backend;
  final int retentionLimit;

  Future<List<HistoryWorkout>> load() async {
    try {
      final raw = await _backend.getString(key);
      if (raw == null) return const [];
      final root = jsonDecode(raw) as Map<String, Object?>;
      if (root['version'] != version) return const [];
      return (root['workouts'] as List<Object?>)
          .map(HistoryWorkout.tryParse)
          .whereType<HistoryWorkout>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveWorkout(WorkoutState workout, {String? note}) async {
    if (workout.completedSets.isEmpty) return;
    final existing = await load();
    final updated = [
      ...existing,
      HistoryWorkout.fromCompletedSets(workout.completedSets, note: note),
    ];
    final retained = updated.length <= retentionLimit
        ? updated
        : updated.sublist(updated.length - retentionLimit);
    await _write(retained, demoVisits: await loadDemoVisits());
  }

  Future<Set<String>> loadDemoVisits() async {
    try {
      final raw = await _backend.getString(key);
      if (raw == null) return const {};
      final root = jsonDecode(raw) as Map<String, Object?>;
      if (root['version'] != version) return const {};
      return (root['demoVisits'] as List<Object?>? ?? const [])
          .cast<String>()
          .toSet();
    } catch (_) {
      return const {};
    }
  }

  Future<void> markDemoVisited(String exerciseId) async {
    final visits = await loadDemoVisits()
      ..add(exerciseId);
    await _write(await load(), demoVisits: visits);
  }

  Future<void> updateNote(DateTime completedAt, String? note) async {
    final workouts = await load();
    final trimmed = note?.trim();
    final updated = workouts
        .map(
          (workout) => workout.completedAt == completedAt
              ? HistoryWorkout(
                  completedAt: workout.completedAt,
                  sets: workout.sets,
                  note: trimmed?.isEmpty ?? true ? null : trimmed,
                )
              : workout,
        )
        .toList(growable: false);
    await _write(updated, demoVisits: await loadDemoVisits());
  }

  Future<void> _write(
    List<HistoryWorkout> workouts, {
    required Set<String> demoVisits,
  }) => _backend.setString(
    key,
    jsonEncode({
      'version': version,
      'workouts': workouts.map((workout) => workout.toJson()).toList(),
      'demoVisits': demoVisits.toList()..sort(),
    }),
  );
}

final historyStorageProvider = Provider<HistoryStorage>(
  (_) => HistoryStorage(SharedPreferencesHistoryBackend()),
);
