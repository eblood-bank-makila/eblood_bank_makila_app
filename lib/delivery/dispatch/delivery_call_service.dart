/// Foreground side of the courier call: shows the call screen (while the
/// insistent notification rings), closes it when the backend says the call
/// is over, and turns the courier's answer into accept / reject calls. Also
/// routes the live-tracking pushes (assigned, closed, progress) to the
/// delivery sheet.
library;

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../blood_search_flow/data/services/visitor_fcm_registration_service.dart';
import '../business/service/DeliveryApiService.dart';
import '../ui/sheet/active_delivery_sheet_controller.dart';
import '../ui/sheet/delivery_sheet.dart';
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
    void Function(NavigatorState navigator, String deliveryId, DeliverySheetRole role)? openSheet,
    void Function(String deliveryId, {String? message})? closeSheet,
  })  : _accept = accept ?? _apiAccept,
        _reject = reject ?? _apiReject,
        _ring = ring ?? ringDeliveryCall,
        _silence = silence ?? silenceDeliveryCall,
        _isCourier = isCourier ?? isActivatedCourier,
        _openActiveDelivery = openActiveDelivery ?? ((n, id) => _openControllerSheet(n, id, DeliverySheetRole.courier)),
        _openSheet = openSheet ?? _openControllerSheet,
        _closeSheet = closeSheet ?? _closeControllerSheet;

  static final instance = DeliveryCallService();

  final Future<String?> Function(String) _accept;
  final Future<void> Function(String) _reject;
  final Future<void> Function(DeliveryCallPayload, Map<String, dynamic>) _ring;
  final Future<void> Function(String) _silence;
  final bool Function() _isCourier;
  final void Function(NavigatorState, String) _openActiveDelivery;
  final void Function(NavigatorState, String, DeliverySheetRole) _openSheet;
  final void Function(String, {String? message}) _closeSheet;

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

  // open() returns when the sheet closes, so it is never awaited here.
  static void _openControllerSheet(NavigatorState navigator, String deliveryId, DeliverySheetRole role) =>
      unawaited(ActiveDeliverySheetController.instance.open(navigator, deliveryId, role));

  static void _closeControllerSheet(String deliveryId, {String? message}) =>
      ActiveDeliverySheetController.instance.closeFor(deliveryId, message: message);

  /// Idempotent. Listens to foreground pushes and to taps on the ringing
  /// notification (app in background or killed).
  Future<void> attach(GlobalKey<NavigatorState> navigatorKey) async {
    if (_navigatorKey != null) return;
    _navigatorKey = navigatorKey;
    FirebaseMessaging.onMessage.listen((m) => handle(m.data));
    FirebaseMessaging.onMessageOpenedApp.listen((m) => handle(m.data, fromTap: true));
    FirebaseMessaging.instance.onTokenRefresh.listen((_) {
      if (_isCourier()) VisitorFcmRegistrationService().registerCurrentDevice(topic: 'courier');
    });
    await initDeliveryCallNotifications((data) => handle(data, fromTap: true));
    // Cold start from a tap on the ringing notification (data-only pushes
    // never come back through getInitialMessage).
    final launched = await deliveryCallLaunchPayload();
    if (launched != null) handle(launched, fromTap: true);
    // Cold start from a tap on a notification message (assigned / progress).
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) handle(initial.data, fromTap: true);
  }

  @visibleForTesting
  void bindNavigator(GlobalKey<NavigatorState> navigatorKey) => _navigatorKey = navigatorKey;

  /// The navigator, waiting for it when a notification tap cold-started the
  /// app: attach() runs before runApp, so the screen appears a few frames later.
  Future<NavigatorState?> _navigator({required bool wait}) async {
    for (var i = 0; wait && _navigatorKey != null && _navigatorKey!.currentState == null && i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return _navigatorKey?.currentState;
  }

  /// Entry point for every push / notification tap carrying delivery data.
  /// [fromTap]: the user tapped the notification (a push seen in the
  /// foreground is not a request to open anything, except for a new assignment).
  Future<void> handle(Map<String, dynamic> data, {bool fromTap = false}) async {
    final closed = DeliveryCallClosed.tryParse(data);
    if (closed != null) {
      await _silence(closed.deliveryId);
      if (_showing == closed.deliveryId) _closed?.value = closed.message;
      return;
    }
    final assigned = DeliveryAssigned.tryParse(data);
    if (assigned != null) {
      if (!_isCourier()) return;
      final navigator = await _navigator(wait: fromTap);
      if (navigator != null) _openActiveDelivery(navigator, assigned.deliveryId);
      return;
    }
    final gone = DeliveryClosed.tryParse(data);
    if (gone != null) {
      _closeSheet(gone.deliveryId, message: gone.messageKey.tr);
      return;
    }
    final progress = DeliveryProgress.tryParse(data);
    if (progress != null) {
      if (!fromTap) return;
      final navigator = await _navigator(wait: true);
      if (navigator != null) {
        _openSheet(navigator, progress.deliveryId, progress.isSeller ? DeliverySheetRole.seller : DeliverySheetRole.buyer);
      }
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
    debugPrint('[delivery-call] ${call.deliveryId}: ${result?.outcome}');
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
