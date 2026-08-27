import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pose_camera_page.dart';
import '../session_controller.dart';
import 'exercise_select_page.dart';
import 'session_summary_page.dart';

class SessionFlow extends ConsumerWidget {
  const SessionFlow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref.watch(
      sessionControllerProvider.select((state) => state.phase),
    );
    return switch (phase) {
      SessionPhase.idle => const ExerciseSelectPage(),
      SessionPhase.tracking => const PoseCameraPage(),
      SessionPhase.complete => const SessionSummaryPage(),
    };
  }
}
