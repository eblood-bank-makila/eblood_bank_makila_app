/// Courier presence: feeds the admin console's « En ligne » column and the
/// courier dispatch (who to ring, how far from the blood bank).
///
/// While an ACTIVATED courier is logged in with the app in the foreground we
/// send `online: true` (with the last position when location is allowed) at
/// once and every 60 s. Going to the background only stops the pings: the
/// console shows offline after 3 min on its own, and the dispatch keeps
/// ringing an on-duty courier whose screen fell asleep (Yango-style).
/// `online: false` is sent on logout only. The courier's push token is
/// registered once per login so the dispatch can reach this phone.
library;

import 'dart:async';

import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:eblood_bank_mak_app/blood_search_flow/data/services/visitor_fcm_registration_service.dart';
import 'package:eblood_bank_mak_app/delivery/dispatch/courier_profile.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';

class CourierPresenceService with WidgetsBindingObserver {
  CourierPresenceService({
    required this.send,
    this.isCourier = isActivatedCourier,
    this.periodic = Timer.periodic,
    this.locate = _noPosition,
    this.registerToken = _noRegistration,
  });

  static final instance = CourierPresenceService(
    send: _put,
    locate: lastPosition,
    registerToken: _registerCourierToken,
  );

  static const interval = Duration(seconds: 60);

  /// Sends one presence call with [body]; returns the HTTP status code.
  final Future<int?> Function(Map<String, dynamic> body) send;
  final bool Function() isCourier;
  final Timer Function(Duration, void Function(Timer)) periodic;

  /// `{lat, lng, accuracy}` or null when unknown / not allowed.
  final Future<Map<String, double>?> Function() locate;
  final Future<void> Function() registerToken;

  bool _attached = false;
  bool _foreground = true;
  bool _noCourierRecord = false;
  bool _tokenRegistered = false;
  Timer? _timer;
  Future<void>? _inFlight;

  static Future<int?> _put(Map<String, dynamic> body) async => (await putWithDio(
        '/eblood-connect/delivery-assignment/presence',
        body: body,
      ))
          .statusCode;

  static Future<Map<String, double>?> _noPosition() async => null;
  static Future<void> _noRegistration() async {}

  /// Best-effort `{lat, lng, accuracy}`: never throws, null when unknown or not allowed.
  static Future<Map<String, double>?> lastPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) return null;
      final pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 8),
            ),
          );
      return {'lat': pos.latitude, 'lng': pos.longitude, 'accuracy': pos.accuracy};
    } catch (_) {
      return null; // no position: the courier still rings city-wide
    }
  }

  static Future<void> _registerCourierToken() async {
    // Android 13+: calls only ring once notifications are allowed.
    await FirebaseMessaging.instance.requestPermission();
    await VisitorFcmRegistrationService().registerCurrentDevice(topic: 'courier');
  }

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

  /// Starts pinging if an activated courier is logged in and the app is in
  /// front; goes offline if the account is no longer a courier (logout).
  void refresh() {
    if (!isCourier()) {
      _noCourierRecord = false; // the next login may be a real courier
      _tokenRegistered = false;
      _goOffline();
      return;
    }
    if (!_tokenRegistered) {
      _tokenRegistered = true;
      unawaited(registerToken().catchError((Object e) => debugPrint('[presence] token registration failed: $e')));
    }
    if (_foreground && !_noCourierRecord && _timer == null) {
      _timer = periodic(interval, (_) => _ping(true));
      _ping(true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _foreground = true;
      refresh();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      _foreground = false;
      _timer?.cancel(); // no "offline": an on-duty courier must still ring
      _timer = null;
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
      final body = <String, dynamic>{'online': online};
      if (online) body.addAll(await locate() ?? const {});
      final code = await send(body);
      // 404: no courier record. 403: courier not activated (or suspended) in
      // the console. Either way stop until the next login re-evaluates.
      if (code == 404 || code == 403) {
        debugPrint('[presence] $code for this account, stopping');
        _noCourierRecord = true;
        _timer?.cancel();
        _timer = null;
      }
    } catch (e) {
      debugPrint('[presence] online=$online failed: $e');
    }
  }
}
