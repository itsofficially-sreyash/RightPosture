import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_controller.dart';
import 'ui/app_theme.dart';
import 'ui/session_flow.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SharedPreferencesSettingsStorage(SharedPreferencesAsync());
  CoachingPreferences preferences;
  try {
    preferences = await storage.load();
  } catch (_) {
    preferences = const CoachingPreferences();
  }
  runApp(
    ProviderScope(
      overrides: [
        settingsStorageProvider.overrideWithValue(storage),
        initialCoachingPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const RightPostureApp(),
    ),
  );
}

class RightPostureApp extends StatelessWidget {
  const RightPostureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SessionFlow(),
    );
  }
}
