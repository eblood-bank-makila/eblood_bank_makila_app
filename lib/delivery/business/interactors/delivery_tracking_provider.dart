/// Live tracking of one delivery: polls the tracking read while somebody listens
/// (the delivery sheet, or the courier's minimized bar), so nothing runs once
/// both are closed.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/delivery_tracking.dart';
import '../service/DeliveryApiService.dart';

/// The stream ended on purpose because the caller may no longer see this delivery ([forbidden]).
class DeliveryTrackingClosed implements Exception {
  final bool forbidden;
  const DeliveryTrackingClosed({this.forbidden = false});

  @override
  String toString() => 'DeliveryTrackingClosed(forbidden: $forbidden)';
}

/// Fetches now, then every [every]. A failed tick (500, network) is skipped and the
/// last value stays; a 403 errors with [DeliveryTrackingClosed] and closes; a
/// `cancelled` phase is emitted, then the stream closes. A slow fetch never overlaps the next,
/// and one that takes longer than [timeout] counts as a failed tick (a stalled socket must not freeze the polling).
/// No fetch while the app is not [inFront] (the minimized bar outlives the screen): the next tick back in front refreshes.
Stream<DeliveryTracking> pollDeliveryTracking(
  String deliveryId, {
  required Future<ApiResponse<Map<String, dynamic>>> Function(String) fetch,
  Duration every = const Duration(seconds: 10),
  Duration timeout = const Duration(seconds: 8),
  bool Function() inFront = _appInFront,
}) {
  late final StreamController<DeliveryTracking> out;
  Timer? timer;
  var busy = false;

  void stop() {
    timer?.cancel();
    if (!out.isClosed) out.close();
  }

  Future<void> tick() async {
    if (busy || !inFront()) return;
    busy = true;
    try {
      final res = await fetch(deliveryId).timeout(timeout);
      if (out.isClosed) return;
      if (res.statusCode == 403) {
        out.addError(const DeliveryTrackingClosed(forbidden: true));
        stop();
      } else if (res.success && res.data != null) {
        final tracking = DeliveryTracking.fromJson(res.data!);
        out.add(tracking);
        if (tracking.isCancelled) stop();
      }
    } catch (e) {
      // Skip this tick; the next one retries.
      if (kDebugMode) debugPrint('[tracking] tick failed: $e');
    } finally {
      busy = false;
    }
  }

  out = StreamController<DeliveryTracking>(
    onListen: () {
      tick();
      timer = Timer.periodic(every, (_) => tick());
    },
    onCancel: () => timer?.cancel(),
  );
  return out.stream;
}

/// Unknown (no lifecycle event yet) counts as in front.
bool _appInFront() {
  final state = WidgetsBinding.instance.lifecycleState;
  return state == null || state == AppLifecycleState.resumed;
}

final deliveryTrackingProvider = StreamProvider.autoDispose.family<DeliveryTracking, String>(
  (ref, deliveryId) => pollDeliveryTracking(deliveryId, fetch: DeliveryApiService().getDeliveryTracking),
);
