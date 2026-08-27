import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:right_posture/async_serial_queue.dart';

void main() {
  test('serializes start-pause-resume during initialization', () async {
    final queue = AsyncSerialQueue();
    final firstInitialization = Completer<void>();
    final events = <String>[];

    final start = queue.run(() async {
      events.add('start-1');
      await firstInitialization.future;
      events.add('started-1');
    });
    final pause = queue.run(() async => events.add('pause'));
    final resume = queue.run(() async {
      events.add('start-2');
      events.add('started-2');
    });

    await Future<void>.delayed(Duration.zero);
    expect(events, ['start-1']);
    firstInitialization.complete();
    await Future.wait([start, pause, resume]);
    expect(events, ['start-1', 'started-1', 'pause', 'start-2', 'started-2']);
  });

  test('continues after a queued operation fails', () async {
    final queue = AsyncSerialQueue();
    await expectLater(
      queue.run(() async => throw StateError('failed')),
      throwsStateError,
    );
    var completed = false;
    await queue.run(() async => completed = true);
    expect(completed, isTrue);
  });
}
