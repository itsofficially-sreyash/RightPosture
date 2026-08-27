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

  test('haptics fire once for depth, warning, and degradation', () async {
    final haptics = <CueHaptic>[];
    final coordinator = CoachingCueCoordinator(
      haptic: (cue) async => haptics.add(cue),
    );
    addTearDown(coordinator.close);
    const preferences = CoachingPreferences(ttsEnabled: false);

    coordinator.handle(
      preferences: preferences,
      coaching: SquatCoaching.depthGood,
    );
    coordinator.handle(
      preferences: preferences,
      coaching: SquatCoaching.depthGood,
    );
    coordinator.handle(
      preferences: preferences,
      coaching: SquatCoaching.standUp,
      latestRep: Rep(
        number: 4,
        angles: const {'knee': 125},
        status: RepStatus.warning,
      ),
    );
    coordinator.handle(
      preferences: preferences,
      coaching: SquatCoaching.standUp,
      latestRep: Rep(
        number: 5,
        angles: const {'knee': 130},
        status: RepStatus.degraded,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(haptics, [CueHaptic.depth, CueHaptic.warning, CueHaptic.degraded]);
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
}
