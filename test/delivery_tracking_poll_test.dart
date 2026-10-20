/// The delivery sheet polls the tracking read every 10 s while it is open.
/// These tests pin the polling rules: failed or hung ticks are skipped, a 403 or a
/// cancelled delivery closes the stream, and a cancelled subscription stops fetching.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
// Transitive dependency of flutter_test (what the framework's own fake time uses).
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';

import 'package:eblood_bank_mak_app/delivery/business/interactors/delivery_tracking_provider.dart';
import 'package:eblood_bank_mak_app/delivery/business/model/delivery_tracking.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/DeliveryApiService.dart';

typedef _Reply = ApiResponse<Map<String, dynamic>>;
typedef _Fetch = Future<_Reply> Function(String);

_Reply _ok(String phase) => ApiResponse.success({'id': 'd1', 'delivery_phase': phase});

class _Run {
  final values = <DeliveryTracking>[];
  final errors = <Object>[];
  final done = <bool>[];
  final ids = <String>[];
  late final StreamSubscription<DeliveryTracking> sub;

  int get fetches => ids.length;
}

void main() {
  const tick = Duration(seconds: 10);

  /// Starts polling under fake time. [fetch] is called once per tick; every id it receives is recorded in `ids`.
  _Run start(_Fetch fetch, {Duration every = tick, Duration timeout = const Duration(seconds: 8)}) {
    final run = _Run();
    run.sub = pollDeliveryTracking(
      'd1',
      fetch: (id) {
        run.ids.add(id);
        return fetch(id);
      },
      every: every,
      timeout: timeout,
    ).listen(run.values.add, onError: run.errors.add, onDone: () => run.done.add(true));
    return run;
  }

  /// Answers with [replies] one per fetch (the last one repeats).
  _Run startWith(List<_Reply> replies) {
    var calls = 0;
    return start((_) async => replies[calls++ < replies.length ? calls - 1 : replies.length - 1]);
  }

  test('fetches immediately, then every tick', () {
    fakeAsync((async) {
      final s = startWith([_ok('assigned')]);
      async.flushMicrotasks();
      expect(s.fetches, 1);
      async.elapse(tick);
      expect(s.fetches, 2);
      expect(s.ids, ['d1', 'd1']);
      expect(s.values, hasLength(2));
      expect(s.values.first.phase, 'assigned');
      s.sub.cancel();
    });
  });

  test('a failed tick (500, network) keeps the stream alive and the last value', () {
    fakeAsync((async) {
      final s = startWith([_ok('assigned'), ApiResponse.error('boom', statusCode: 500), ApiResponse.error('Network error'), _ok('picked_up')]);
      async.flushMicrotasks();
      async.elapse(tick * 3);
      expect(s.errors, isEmpty);
      expect(s.done, isEmpty);
      expect(s.values.map((v) => v.phase), ['assigned', 'picked_up']);
      s.sub.cancel();
    });
  });

  test('a fetch that never answers times out: the next tick fetches again and emits', () {
    fakeAsync((async) {
      var calls = 0;
      final s = start((_) => calls++ == 0 ? Completer<_Reply>().future : Future.value(_ok('picked_up')), timeout: const Duration(seconds: 5));
      async.elapse(const Duration(seconds: 6));
      expect(s.fetches, 1);
      expect(s.values, isEmpty);
      async.elapse(const Duration(seconds: 5)); // t = 11 s: second tick
      expect(s.fetches, 2);
      expect(s.values.single.phase, 'picked_up');
      expect(s.errors, isEmpty);
      s.sub.cancel();
    });
  });

  test('a slow fetch is never overlapped by the next tick', () {
    fakeAsync((async) {
      final slow = Completer<_Reply>();
      final s = start((_) => slow.future, every: const Duration(seconds: 2), timeout: const Duration(seconds: 30));
      async.elapse(const Duration(seconds: 9)); // 4 ticks went by while the first fetch is in flight
      expect(s.fetches, 1);
      slow.complete(_ok('assigned'));
      async.flushMicrotasks();
      expect(s.values.single.phase, 'assigned');
      async.elapse(const Duration(seconds: 2));
      expect(s.fetches, 2);
      s.sub.cancel();
    });
  });

  test('a 403 emits DeliveryTrackingClosed(forbidden) and closes', () {
    fakeAsync((async) {
      final s = startWith([_ok('assigned'), ApiResponse.error('no', statusCode: 403)]);
      async.flushMicrotasks();
      async.elapse(tick);
      expect(s.errors.single, isA<DeliveryTrackingClosed>().having((e) => e.forbidden, 'forbidden', isTrue));
      expect(s.done, [true]);
      final before = s.fetches;
      async.elapse(tick * 3);
      expect(s.fetches, before);
    });
  });

  test('a 403 on the very first fetch errors and closes with no value', () {
    fakeAsync((async) {
      final s = startWith([ApiResponse.error('no', statusCode: 403)]);
      async.flushMicrotasks();
      expect(s.values, isEmpty);
      expect(s.errors.single, isA<DeliveryTrackingClosed>().having((e) => e.forbidden, 'forbidden', isTrue));
      expect(s.done, [true]);
      async.elapse(tick * 3);
      expect(s.fetches, 1);
    });
  });

  test('a cancelled delivery emits the value, then closes', () {
    fakeAsync((async) {
      final s = startWith([_ok('cancelled')]);
      async.flushMicrotasks();
      expect(s.values.single.isCancelled, isTrue);
      expect(s.done, [true]);
      async.elapse(tick * 3);
      expect(s.fetches, 1);
    });
  });

  test('cancelling the subscription stops fetching', () {
    fakeAsync((async) {
      final s = startWith([_ok('assigned')]);
      async.flushMicrotasks();
      s.sub.cancel();
      async.elapse(tick * 3);
      expect(s.fetches, 1);
    });
  });
}
