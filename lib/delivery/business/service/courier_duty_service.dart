/// « En service / Hors service »: the courier chooses when the dispatch may
/// ring them. While on duty the phone shares its position in the background
/// (geolocator's foreground service, with a permanent notification):
/// [CourierPresenceService] pings with the latest fresh fix, and during a
/// delivery each fix goes to update-location for those following it live.
library;

import 'dart:async';

import 'package:eblood_bank_mak_app/core/services/location_access.dart';
import 'package:eblood_bank_mak_app/core/services/location_tracking_service.dart';
import 'package:eblood_bank_mak_app/core/services/session_identity.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/DeliveryApiService.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/courier_presence_service.dart';
import 'package:eblood_bank_mak_app/delivery/dispatch/courier_profile.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/active_delivery_sheet_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';

typedef DutyFix = ({double lat, double lng, double accuracy});

class CourierDutyService extends ChangeNotifier {
  CourierDutyService({
    required this.sendPresence,
    required this.sendDeliveryLocation,
    required this.positions,
    required this.ensurePermission,
    required this.hasPermission,
    required this.hasActiveDelivery,
    this.clock = DateTime.now,
    required this.storage,
    this.suspendOtherTracking = _nothing,
    this.resumeOtherTracking = _nothing,
    this.resumeDelivery = _noDelivery,
  }) {
    final session = SessionIdentity(storage);
    _unlisten = storage.listenKey('user_profiles', (_) {
      // Another user, a logout, or the console withdrawing the courier profile.
      // Deferred: a storage write inside a GetStorage listener hides the event
      // from the listeners after this one (the sheet controller, presence).
      if (session.changed() || !isActivatedCourier()) scheduleMicrotask(_reset);
    });
  }

  static final CourierDutyService instance = CourierDutyService(
    sendPresence: (body) => CourierPresenceService.instance.send(body),
    sendDeliveryLocation: (lat, lng, accuracy) =>
        DeliveryApiService().updateDeliveryPersonLocation(lat, lng, accuracy: accuracy),
    positions: _positions,
    ensurePermission: _ensurePermission,
    hasPermission: () async => await LocationAccess().status() == LocationAccessStatus.granted,
    // Set by every way a courier gets a delivery (call accepted, console
    // assignment push, the home card, [resumeDelivery]) and cleared when it ends.
    hasActiveDelivery: () => ActiveDeliverySheetController.instance.courierDeliveryId != null,
    storage: GetStorage(),
    suspendOtherTracking: () => LocationTrackingService().suspend(),
    resumeOtherTracking: () => LocationTrackingService().resume(),
    resumeDelivery: _resumeActiveDelivery,
  );

  /// The duty stream: one fix every 15 s, moving or not, so presence always
  /// has one under 2 min old; the foreground service keeps it going in the background.
  static final locationSettings = AndroidSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
    intervalDuration: const Duration(seconds: 15),
    foregroundNotificationConfig: const ForegroundNotificationConfig(
      notificationTitle: 'e-Blood · En service',
      notificationText: 'Position partagée pour les livraisons',
      enableWakeLock: true,
      setOngoing: true,
    ),
  );

  static const _key = 'courier_on_duty';
  static const _deliveryEvery = Duration(seconds: 15);
  static const _freshFor = Duration(minutes: 2);

  /// One presence call; returns the HTTP status code.
  final Future<int?> Function(Map<String, dynamic> body) sendPresence;
  final Future<void> Function(double lat, double lng, double accuracy) sendDeliveryLocation;
  final Stream<DutyFix> Function() positions;

  /// Asks for the location permission if needed; true once it is granted.
  final Future<bool> Function() ensurePermission;

  /// The permission is granted, without asking (app start).
  final Future<bool> Function() hasPermission;
  final bool Function() hasActiveDelivery;
  final DateTime Function() clock;
  final GetStorage storage;

  /// geolocator_android hands every caller the ONE stream it has cached, with
  /// the first caller's settings: the app's own tracking stops while on duty.
  final void Function() suspendOtherTracking;
  final void Function() resumeOtherTracking;

  /// App start, back on duty: picks up the delivery in progress, if any, so
  /// its positions go out again.
  final Future<void> Function() resumeDelivery;

  late final VoidCallback _unlisten;
  bool _onDuty = false;
  bool _ownsStream = false;
  bool _resubscribed = false;
  StreamSubscription<DutyFix>? _subscription;
  DutyFix? _fix;
  DateTime? _fixAt;
  DateTime? _deliverySentAt;

  bool get onDuty => _onDuty;

  /// The stream's latest fix while at most 2 min old, else null: the server
  /// stamps presence positions as live, so an old one must never go out.
  Map<String, double>? get freshFix {
    final fix = _fix, at = _fixAt;
    if (fix == null || at == null || clock().difference(at) > _freshFor) return null;
    return {'lat': fix.lat, 'lng': fix.lng, 'accuracy': fix.accuracy};
  }

  static void _nothing() {}
  static Future<void> _noDelivery() async {}

  static Stream<DutyFix> _positions() => Geolocator.getPositionStream(locationSettings: locationSettings)
      .map((p) => (lat: p.latitude, lng: p.longitude, accuracy: p.accuracy));

  static Future<bool> _ensurePermission() async {
    final access = LocationAccess();
    var status = await access.status();
    if (status == LocationAccessStatus.denied) status = await access.fix(); // the permission prompt
    return status == LocationAccessStatus.granted;
  }

  static Future<void> _resumeActiveDelivery() async {
    final id = (await DeliveryApiService().getActiveDelivery()).data?.id;
    if (id != null) ActiveDeliverySheetController.instance.adopt(id);
  }

  /// Returns a translation key when the change is refused.
  Future<String?> setOnDuty(bool value) async {
    if (value == _onDuty) return null;
    if (value) {
      if (!await ensurePermission()) return 'duty_location_needed';
      final code = await _send({'online': true});
      if (code == null || code < 200 || code >= 300) return 'duty_server_error';
      _start();
      await _save(true);
      return null;
    }
    if (hasActiveDelivery()) return 'duty_finish_delivery_first';
    if (await _send({'online': false}) == 409) return 'duty_finish_delivery_first';
    // No answer (network) still goes off: presence stops, so the dispatch stops ringing within 30 min.
    _stop();
    await _save(false);
    return null;
  }

  /// App start: back on duty if it was left on and location is still allowed.
  Future<void> resumeIfNeeded() async {
    if (_onDuty || storage.read(_key) != true) return;
    if (await hasPermission()) {
      _start();
      await _save(true);
      unawaited(resumeDelivery().catchError((Object e) => debugPrint('[duty] active delivery: $e')));
    } else {
      await _save(false);
    }
  }

  Future<int?> _send(Map<String, dynamic> body) async {
    try {
      return await sendPresence(body);
    } catch (e) {
      debugPrint('[duty] presence $body failed: $e');
      return null;
    }
  }

  void _start() {
    if (_ownsStream) return;
    _ownsStream = true;
    suspendOtherTracking(); // its listener must be gone before ours subscribes
    _resubscribed = false;
    _listen();
  }

  void _listen() {
    _subscription = positions().listen(
      _onFix,
      onError: (Object e) => debugPrint('[duty] position stream: $e'),
      onDone: _onDone,
    );
  }

  /// The stream ended by itself: one new subscription, then off duty rather
  /// than « En service » with no fixes.
  void _onDone() {
    _subscription = null;
    if (!_resubscribed) {
      _resubscribed = true;
      _listen();
    } else {
      debugPrint('[duty] position stream ended twice, going off duty');
      _reset();
    }
  }

  void _stop() {
    final subscription = _subscription;
    _subscription = null;
    _fix = null;
    _fixAt = null;
    _deliverySentAt = null;
    if (!_ownsStream) return;
    _ownsStream = false;
    // The plugin drops its cached stream once its last listener has cancelled:
    // the app's own tracking then gets a fresh one with its own settings.
    unawaited((subscription?.cancel() ?? Future<void>.value()).whenComplete(resumeOtherTracking));
  }

  Future<void> _save(bool value) async {
    _onDuty = value;
    notifyListeners();
    await storage.write(_key, value);
  }

  void _onFix(DutyFix fix) {
    final now = clock();
    _fix = fix;
    _fixAt = now;
    if (!hasActiveDelivery()) return;
    final last = _deliverySentAt;
    if (last != null && now.difference(last) < _deliveryEvery) return;
    _deliverySentAt = now;
    unawaited(sendDeliveryLocation(fix.lat, fix.lng, fix.accuracy)
        .catchError((Object e) => debugPrint('[duty] delivery location failed: $e')));
  }

  /// Off duty without a server call: presence's own "offline" follows the change.
  void _reset() {
    if (!_onDuty && storage.read(_key) != true) return;
    _stop();
    unawaited(_save(false));
  }

  @override
  void dispose() {
    _unlisten();
    _stop();
    super.dispose();
  }
}
