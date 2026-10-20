/// The delivery sheet polls the tracking read every 10 s while it is open.
/// These tests pin the polling rules: failed ticks are skipped, a 403 or a
/// cancelled delivery closes the stream, and a cancelled subscription stops fetching.
library;

import 'package:flutter_test/flutter_test.dart';
// Transitive dependency of flutter_test (what the framework's own fake time uses).
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';

import 'package:eblood_bank_mak_app/delivery/business/interactors/delivery_tracking_provider.dart';
import 'package:eblood_bank_mak_app/delivery/business/model/delivery_tracking.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/DeliveryApiService.dart';

typedef _Reply = ApiResponse<Map<String, dynamic>>;

_Reply _ok(String phase) => ApiResponse.success({'id': 'd1', 'delivery_phase': phase});

void main() {
  const tick = Duration(seconds: 10);

  /// Runs the stream under fake time; [replies] is consumed one per fetch (the last repeats).
  ({List<DeliveryTracking> values, List<Object> errors, List<bool> done, int Function() fetches, void Function() cancel})
      listen(List<_Reply> replies) {
    var calls = 0;
    final values = <DeliveryTracking>[];
    final errors = <Object>[];
    final done = <bool>[];
    final sub = pollDeliveryTracking('d1', fetch: (id) async {
      expect(id, 'd1');
      return replies[calls++ < replies.length ? calls - 1 : replies.length - 1];
    }).listen(values.add, onError: errors.add, onDone: () => done.add(true));
    return (values: values, errors: errors, done: done, fetches: () => calls, cancel: sub.cancel);
  }

  test('fetches immediately, then every tick', () {
    fakeAsync((async) {
      final s = listen([_ok('assigned')]);
      async.flushMicrotasks();
      expect(s.fetches(), 1);
      async.elapse(tick);
      expect(s.fetches(), 2);
      expect(s.values, hasLength(2));
      expect(s.values.first.phase, 'assigned');
      s.cancel();
    });
  });

  test('a failed tick (500, network) keeps the stream alive and the last value', () {
    fakeAsync((async) {
      final s = listen([_ok('assigned'), ApiResponse.error('boom', statusCode: 500), ApiResponse.error('Network error'), _ok('picked_up')]);
      async.flushMicrotasks();
      async.elapse(tick * 3);
      expect(s.errors, isEmpty);
      expect(s.done, isEmpty);
      expect(s.values.map((v) => v.phase), ['assigned', 'picked_up']);
      s.cancel();
    });
  });

  test('a 403 emits DeliveryTrackingClosed(forbidden) and closes', () {
    fakeAsync((async) {
      final s = listen([_ok('assigned'), ApiResponse.error('no', statusCode: 403)]);
      async.flushMicrotasks();
      async.elapse(tick);
      expect(s.errors.single, isA<DeliveryTrackingClosed>().having((e) => e.forbidden, 'forbidden', isTrue));
      expect(s.done, [true]);
      final before = s.fetches();
      async.elapse(tick * 3);
      expect(s.fetches(), before);
    });
  });

  test('a cancelled delivery emits the value, then closes', () {
    fakeAsync((async) {
      final s = listen([_ok('cancelled')]);
      async.flushMicrotasks();
      expect(s.values.single.isCancelled, isTrue);
      expect(s.done, [true]);
      async.elapse(tick * 3);
      expect(s.fetches(), 1);
    });
  });

  test('cancelling the subscription stops fetching', () {
    fakeAsync((async) {
      final s = listen([_ok('assigned')]);
      async.flushMicrotasks();
      s.cancel();
      async.elapse(tick * 3);
      expect(s.fetches(), 1);
    });
  });
}
