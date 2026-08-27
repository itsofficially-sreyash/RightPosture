import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ui/app_theme.dart';
import 'ui/session_flow.dart';

void main() => runApp(const ProviderScope(child: RightPostureApp()));

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
