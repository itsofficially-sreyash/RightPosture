import 'dart:async';

class AsyncSerialQueue {
  Future<void> _tail = Future.value();

  Future<void> run(Future<void> Function() action) {
    final result = Completer<void>();
    _tail = _tail.then((_) async {
      try {
        await action();
        result.complete();
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  Future<void> wait() => _tail;
}
