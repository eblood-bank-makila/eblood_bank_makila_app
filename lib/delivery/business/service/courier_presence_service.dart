/// Courier online presence for the admin console's "En ligne" column.
///
/// The server counts a courier as online only if he pinged within the last
/// 3 minutes, so while a courier is logged in with the app in the foreground
/// we send `online: true` at once and every 60 s, and `online: false` when
/// the app goes to the background or the courier logs out.
library;

import 'dart:async';

import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:eblood_bank_mak_app/orders/dead_hand/dead_hand_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get_storage/get_storage.dart';

class CourierPresenceService with WidgetsBindingObserver {
  CourierPresenceService({
    required this.send,
    this.isCourier = DeadHandService.isDeliveryPersonProfile,
    this.periodic = Timer.periodic,
  });

  static final instance = CourierPresenceService(send: _put);

  static const interval = Duration(seconds: 60);

  /// Sends one presence call; returns the HTTP status code.
  final Future<int?> Function(bool online) send;
  final bool Function() isCourier;
  final Timer Function(Duration, void Function(Timer)) periodic;

  bool _attached = false;
  bool _foreground = true;
  bool _noCourierRecord = false;
  Timer? _timer;
  Future<void>? _inFlight;

  static Future<int?> _put(bool online) async => (await putWithDio(
        '/eblood-connect/delivery-assignment/presence',
        body: {'online': online},
      ))
          .statusCode;

  /// Idempotent. Call once, after dotenv and GetStorage are ready.
  void attach() {
    if (_attached) return;
    _attached = true;
    WidgetsBinding.instance.addObserver(this);
    // Every login path writes `user_profiles` and every logout removes it,
    // so this one listener starts and stops presence with the session.
    GetStorage().listenKey('user_profiles', (_) => refresh());
    refresh();
  }

  /// Starts pinging if a courier is logged in and the app is in front;
  /// goes offline if the account is no longer a courier.
  void refresh() {
    if (!isCourier()) {
      _noCourierRecord = false; // the next login may be a real courier
      _goOffline();
    } else if (_foreground && !_noCourierRecord && _timer == null) {
      _timer = periodic(interval, (_) => _ping(true));
      _ping(true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      refresh();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      _goOffline();
    }
  }

  void _goOffline() {
    if (_timer == null) return;
    _timer!.cancel();
    _timer = null;
    _ping(false);
  }

  Future<void> _ping(bool online) async {
    // One call at a time: a tick that lands mid-flight is dropped, and
    // "offline" waits so it reaches the server after the last "online".
    if (_inFlight != null) {
      if (online) return;
      await _inFlight;
    }
    final call = _call(online);
    _inFlight = call;
    await call;
    if (identical(_inFlight, call)) _inFlight = null;
  }

  Future<void> _call(bool online) async {
    try {
      if (await send(online) == 404) {
        debugPrint('[presence] no courier record for this account, stopping');
        _noCourierRecord = true;
        _timer?.cancel();
        _timer = null;
      }
    } catch (e) {
      debugPrint('[presence] online=$online failed: $e');
    }
  }
}
