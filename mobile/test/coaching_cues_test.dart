import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/coaching_cues.dart';
import 'package:right_posture/domain/models.dart';
import 'package:right_posture/domain/squat_rep_detector.dart';
import 'package:right_posture/settings_controller.dart';

void main() {
  test('voice cues deduplicate repeated coaching', () async {
    final spoken = <String>[];
    final coordinator = CoachingCueCoordinator(
      synthesize: (text) async {
        spoken.add(text);
        return Uint8List.fromList([1]);
      },
      play: (_) async {},
      cooldown: Duration.zero,
    );
    addTearDown(coordinator.close);

    coordinator.handle(
      preferences: const CoachingPreferences(hapticsEnabled: false),
      coaching: SquatCoaching.goLower,
    );
    await Future<void>.delayed(Duration.zero);
    coordinator.handle(
      preferences: const CoachingPreferences(hapticsEnabled: false),
      coaching: SquatCoaching.goLower,
    );
    await Future<void>.delayed(Duration.zero);

    expect(spoken, ['Go lower']);
  });

  test('disabled voice never synthesizes', () async {
    var synthesized = false;
    final coordinator = CoachingCueCoordinator(
      synthesize: (_) async {
        synthesized = true;
        return Uint8List(0);
      },
      play: (_) async {},
    );
    addTearDown(coordinator.close);

    coordinator.handle(
      preferences: const CoachingPreferences(
        ttsEnabled: false,
        hapticsEnabled: false,
      ),
      coaching: SquatCoaching.ready,
    );
    await Future<void>.delayed(Duration.zero);
    expect(synthesized, isFalse);
  });

  test('cooldown keeps only the latest pending instruction', () async {
    final spoken = <String>[];
    final coordinator = CoachingCueCoordinator(
      synthesize: (text) async {
        spoken.add(text);
        return Uint8List.fromList([1]);
      },
      play: (_) async {},
      cooldown: const Duration(milliseconds: 20),
    );
    addTearDown(coordinator.close);

    coordinator.handle(
      preferences: const CoachingPreferences(hapticsEnabled: false),
      coaching: SquatCoaching.ready,
    );
    await Future<void>.delayed(Duration.zero);
    coordinator.handle(
      preferences: const CoachingPreferences(hapticsEnabled: false),
      coaching: SquatCoaching.goLower,
    );
    coordinator.handle(
      preferences: const CoachingPreferences(hapticsEnabled: false),
      coaching: SquatCoaching.standUp,
    );
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(spoken, ['Ready — squat down', 'Stand up']);
  });

  test(
    'in-flight synthesis is serialized and stale prompt is skipped',
    () async {
      final firstSynthesis = Completer<Uint8List>();
      final played = <int>[];
      var calls = 0;
      final coordinator = CoachingCueCoordinator(
        synthesize: (_) {
          calls++;
          return calls == 1
              ? firstSynthesis.future
              : Future.value(Uint8List.fromList([2]));
        },
        play: (bytes) async => played.add(bytes.first),
        cooldown: Duration.zero,
      );
      addTearDown(coordinator.close);

      coordinator.handle(
        preferences: const CoachingPreferences(hapticsEnabled: false),
        coaching: SquatCoaching.ready,
      );
      coordinator.handle(
        preferences: const CoachingPreferences(hapticsEnabled: false),
        coaching: SquatCoaching.goLower,
      );
      firstSynthesis.complete(Uint8List.fromList([1]));
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(played, [2]);
    },
  );

  test('degraded rep cues once per session and rep number', () async {
    final haptics = <CueHaptic>[];
    var sounds = 0;
    final coordinator = CoachingCueCoordinator(
      haptic: (cue) async => haptics.add(cue),
      sound: () async => sounds++,
    );
    addTearDown(coordinator.close);
    const preferences = CoachingPreferences();
    final degraded = Rep(
      number: 5,
      angles: const {},
      status: RepStatus.degraded,
    );

    coordinator.handleRepCue(
      preferences: preferences,
      sessionId: 'squat:1',
      latestRep: degraded,
    );
    coordinator.handleRepCue(
      preferences: preferences,
      sessionId: 'squat:1',
      latestRep: degraded,
    );
    coordinator.handleRepCue(
      preferences: preferences,
      sessionId: 'squat:1',
      latestRep: Rep(number: 6, angles: const {}, status: RepStatus.degraded),
    );
    coordinator.handleRepCue(
      preferences: preferences,
      sessionId: 'squat:2',
      latestRep: degraded,
    );
    await Future<void>.delayed(Duration.zero);

    expect(haptics, [
      CueHaptic.degraded,
      CueHaptic.degraded,
      CueHaptic.degraded,
    ]);
    expect(sounds, 3);
  });

  test('non-degraded reps and disabled channels stay silent', () async {
    var haptics = 0;
    var sounds = 0;
    final coordinator = CoachingCueCoordinator(
      haptic: (_) async => haptics++,
      sound: () async => sounds++,
    );
    addTearDown(coordinator.close);
    for (final status in [
      RepStatus.calibrating,
      RepStatus.good,
      RepStatus.warning,
    ]) {
      coordinator.handleRepCue(
        preferences: const CoachingPreferences(),
        sessionId: 'squat:1',
        latestRep: Rep(number: status.index, angles: const {}, status: status),
      );
    }
    coordinator.handleRepCue(
      preferences: const CoachingPreferences(
        hapticsEnabled: false,
        soundEnabled: false,
      ),
      sessionId: 'squat:1',
      latestRep: Rep(number: 4, angles: const {}, status: RepStatus.degraded),
    );
    coordinator.handleRepCue(
      preferences: const CoachingPreferences(),
      sessionId: 'squat:1',
      latestRep: Rep(number: 4, angles: const {}, status: RepStatus.degraded),
    );
    await Future<void>.delayed(Duration.zero);
    expect(haptics, 0);
    expect(sounds, 0);
  });

  test('background cue is consumed and cannot replay on resume', () async {
    var cues = 0;
    final coordinator = CoachingCueCoordinator(
      haptic: (_) async => cues++,
      sound: () async => cues++,
    );
    addTearDown(coordinator.close);
    final rep = Rep(number: 5, angles: const {}, status: RepStatus.degraded);
    coordinator.setForeground(false);
    coordinator.handleRepCue(
      preferences: const CoachingPreferences(),
      sessionId: 'squat:1',
      latestRep: rep,
    );
    coordinator.setForeground(true);
    coordinator.handleRepCue(
      preferences: const CoachingPreferences(),
      sessionId: 'squat:1',
      latestRep: rep,
    );
    await Future<void>.delayed(Duration.zero);
    expect(cues, 0);
  });

  test('tracking interruption cancels an in-flight prompt', () async {
    final synthesis = Completer<Uint8List>();
    var played = false;
    final coordinator = CoachingCueCoordinator(
      synthesize: (_) => synthesis.future,
      play: (_) async => played = true,
      stop: () async {},
      cooldown: Duration.zero,
    );
    addTearDown(coordinator.close);
    coordinator.handle(
      preferences: const CoachingPreferences(hapticsEnabled: false),
      coaching: SquatCoaching.ready,
    );
    coordinator.interrupt();
    synthesis.complete(Uint8List.fromList([1]));
    await Future<void>.delayed(Duration.zero);
    expect(played, isFalse);
  });

  test('degraded cue handling never synthesizes rep speech', () async {
    var synthesized = false;
    final haptics = <CueHaptic>[];
    final coordinator = CoachingCueCoordinator(
      synthesize: (_) async {
        synthesized = true;
        return Uint8List(0);
      },
      play: (_) async {},
      haptic: (cue) async => haptics.add(cue),
    );
    addTearDown(coordinator.close);

    coordinator.handleRepCue(
      preferences: const CoachingPreferences(),
      sessionId: 'squat:1',
      latestRep: Rep(number: 4, angles: const {}, status: RepStatus.degraded),
    );
    await Future<void>.delayed(Duration.zero);

    expect(synthesized, isFalse);
    expect(haptics, [CueHaptic.degraded]);
  });
}
