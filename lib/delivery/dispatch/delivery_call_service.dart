/// Foreground side of the courier call: shows the call screen (while the
/// insistent notification rings), closes it when the backend says the call
/// is over, and turns the courier's answer into accept / reject calls.
library;

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../blood_search_flow/data/services/visitor_fcm_registration_service.dart';
import '../business/service/DeliveryApiService.dart';
import '../ui/pages/ActiveDeliveryTrackingPage.dart';
import 'courier_profile.dart';
import 'delivery_call_notifications.dart';
import 'delivery_call_payload.dart';
import 'delivery_call_screen.dart';

class DeliveryCallService {
  DeliveryCallService({
    Future<String?> Function(String deliveryId)? accept,
    Future<void> Function(String deliveryId)? reject,
    Future<void> Function(DeliveryCallPayload call, Map<String, dynamic> data)? ring,
    Future<void> Function(String deliveryId)? silence,
    bool Function()? isCourier,
    void Function(NavigatorState navigator, String deliveryId)? openActiveDelivery,
  })  : _accept = accept ?? _apiAccept,
        _reject = reject ?? _apiReject,
        _ring = ring ?? ringDeliveryCall,
        _silence = silence ?? silenceDeliveryCall,
        _isCourier = isCourier ?? isActivatedCourier,
        _openActiveDelivery = openActiveDelivery ?? _pushActiveDelivery;

  static final instance = DeliveryCallService();

  final Future<String?> Function(String) _accept;
  final Future<void> Function(String) _reject;
  final Future<void> Function(DeliveryCallPayload, Map<String, dynamic>) _ring;
  final Future<void> Function(String) _silence;
  final bool Function() _isCourier;
  final void Function(NavigatorState, String) _openActiveDelivery;

  GlobalKey<NavigatorState>? _navigatorKey;
  String? _showing; // delivery id of the call on screen
  ValueNotifier<String?>? _closed;

  static Future<String?> _apiAccept(String id) async {
    final res = await DeliveryApiService().acceptDeliveryRequest(id);
    return res.success ? null : (res.error ?? 'Course déjà prise.');
  }

  static Future<void> _apiReject(String id) async {
    await DeliveryApiService().rejectDeliveryRequest(id, reason: 'ignored_from_call');
  }

  static void _pushActiveDelivery(NavigatorState navigator, String deliveryId) =>
      navigator.push(MaterialPageRoute(builder: (_) => ActiveDeliveryTrackingPage(deliveryId: deliveryId)));

  /// Idempotent. Listens to foreground pushes and to taps on the ringing
  /// notification (app in background or killed).
  Future<void> attach(GlobalKey<NavigatorState> navigatorKey) async {
    if (_navigatorKey != null) return;
    _navigatorKey = navigatorKey;
    FirebaseMessaging.onMessage.listen((m) => handle(m.data));
    FirebaseMessaging.onMessageOpenedApp.listen((m) => handle(m.data));
    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      if (_isCourier()) VisitorFcmRegistrationService().registerCurrentDevice(topic: 'courier');
    });
    await initDeliveryCallNotifications(handle);
    // Cold start from a tap on the ringing notification (data-only pushes
    // never come back through getInitialMessage).
    final launched = await deliveryCallLaunchPayload();
    if (launched != null) handle(launched);
  }

  @visibleForTesting
  void bindNavigator(GlobalKey<NavigatorState> navigatorKey) => _navigatorKey = navigatorKey;

  /// Entry point for every push / notification tap carrying call data.
  Future<void> handle(Map<String, dynamic> data) async {
    final closed = DeliveryCallClosed.tryParse(data);
    if (closed != null) {
      await _silence(closed.deliveryId);
      if (_showing == closed.deliveryId) _closed?.value = closed.message;
      return;
    }
    final call = DeliveryCallPayload.tryParse(data);
    if (call == null || !_isCourier() || call.timeLeft() == Duration.zero) return;
    if (_showing != null) return; // one call at a time
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      await _ring(call, data); // no screen to show yet: ring; the tap opens it
      return;
    }
    // Claim the screen BEFORE any await: two pushes landing together must
    // not stack two call screens.
    _showing = call.deliveryId;
    _closed = ValueNotifier<String?>(null);
    await _ring(call, data);
    DeliveryCallResult? result;
    try {
      result = await navigator.push<DeliveryCallResult>(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => DeliveryCallScreen(call: call, closedReason: _closed!, accept: _accept),
      ));
    } finally {
      _showing = null;
      _closed = null;
      await _silence(call.deliveryId);
    }
    switch (result?.outcome) {
      case DeliveryCallOutcome.accepted:
        _snack(navigator, result?.message);
        _openActiveDelivery(navigator, call.deliveryId);
      case DeliveryCallOutcome.declined:
        unawaited(_reject(call.deliveryId));
      case DeliveryCallOutcome.closedRemotely:
      case DeliveryCallOutcome.expired:
      case null:
        _snack(navigator, result?.message);
    }
  }

  void _snack(NavigatorState navigator, String? message) {
    if (message == null || message.isEmpty) return;
    final messenger = ScaffoldMessenger.maybeOf(navigator.context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
