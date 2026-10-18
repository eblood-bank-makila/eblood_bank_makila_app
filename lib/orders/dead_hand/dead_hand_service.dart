/// Sprint M — Flutter side of the dead-hand auto-broadcast.
///
/// Singleton wired into `main.dart` after Firebase init. Behaviour:
///   1. On `attach(...)` it subscribes to the `delivery_person` FCM
///      topic IFF the current account is a delivery person, listens
///      to `FirebaseMessaging.onMessage`, and gates every message
///      through `DeadHandAlertPayload.tryParse` so non-dead-hand
///      messages flow through unchanged to the existing handler.
///   2. When a dead-hand message lands, it surfaces
///      `DeadHandAlertScreen` via the app's `navigatorKey` and waits
///      for the user's accept/decline decision.
///   3. On accept, fires `POST /api/v1/orders/dead-hand-claim` with
///      `{order_id, user_id}` — server creates the Delivery row
///      atomically. The verdict (granted / already_claimed / etc.)
///      is shown via a snackbar.
///
/// The service is idempotent on attach — calling it twice is safe.
/// `watchSession` attaches on every courier login and detaches (topic
/// unsubscribed, listeners cancelled) on logout or a non-courier login.
library;

import 'dart:async';

import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import 'dead_hand_alert_dialog.dart';
import 'dead_hand_alert_payload.dart';

class DeadHandService {
  static const String _fcmTopic = 'delivery_person';
  static const String _claimEndpoint = '/orders/dead-hand-claim';

  static bool _attached = false;
  static bool _alertVisible = false;
  static final List<StreamSubscription<RemoteMessage>> _subscriptions = [];

  /// Subscribes (true) or unsubscribes (false) the courier topic.
  /// Swapped in tests, where Firebase is not initialised.
  @visibleForTesting
  static Future<void> Function(bool subscribe) setTopic = (subscribe) =>
      subscribe
          ? FirebaseMessaging.instance.subscribeToTopic(_fcmTopic)
          : FirebaseMessaging.instance.unsubscribeFromTopic(_fcmTopic);

  /// Attaches whenever a courier is logged in and detaches otherwise, at
  /// once and on every session change. Every login path writes
  /// `user_profiles` and every logout removes it, so this one listener
  /// follows the session. Returns the listener's disposer.
  static VoidCallback watchSession({
    required GlobalKey<NavigatorState> navigatorKey,
    required Future<String?> Function() getCurrentUserId,
  }) {
    void sync() => isDeliveryPersonProfile()
        ? attach(navigatorKey: navigatorKey, getCurrentUserId: getCurrentUserId)
        : detach();
    final dispose = GetStorage().listenKey('user_profiles', (_) => sync());
    sync();
    return dispose;
  }

  /// Idempotent: safe to call from multiple bootstrap paths.
  ///
  /// `navigatorKey` is the app's root navigator key (defined in
  /// `lib/main.dart`) so the alert can render above any current
  /// route. `getCurrentUserId` is a closure (instead of a fixed
  /// string) because the user can switch profiles within a session
  /// — we resolve the id at message-receipt time, not at attach
  /// time.
  static Future<void> attach({
    required GlobalKey<NavigatorState> navigatorKey,
    required Future<String?> Function() getCurrentUserId,
  }) async {
    if (_attached) return;
    _attached = true;

    // Listen before the topic await so a detach() during it cancels these.
    _subscriptions.addAll([
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _handleIncoming(message, navigatorKey, getCurrentUserId);
      }),
      // App was opened from a tap on a dead-hand notification — same
      // flow as the live one.
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        _handleIncoming(message, navigatorKey, getCurrentUserId);
      }),
    ]);

    // Topic subscription is best-effort — failure means the courier
    // simply won't receive broadcasts, which is recoverable on next
    // app open or login.
    try {
      await setTopic(true);
      debugPrint('[dead-hand] subscribed to topic: $_fcmTopic');
    } catch (e) {
      debugPrint('[dead-hand] topic subscribe failed: $e');
    }
  }

  /// Idempotent. Stops alerts on this device: on a shared phone the next
  /// account must not ring for courier broadcasts.
  static Future<void> detach() async {
    if (!_attached) return;
    _attached = false;
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    try {
      await setTopic(false);
      debugPrint('[dead-hand] unsubscribed from topic: $_fcmTopic');
    } catch (e) {
      debugPrint('[dead-hand] topic unsubscribe failed: $e');
    }
  }

  /// Quick guard so non-delivery-person logins don't waste cycles
  /// (and don't subscribe to the courier topic).
  static bool isDeliveryPersonProfile() {
    try {
      final storage = GetStorage();
      final profiles = storage.read('user_profiles');
      if (profiles is List) {
        for (final p in profiles) {
          if (p is Map) {
            final flag = (p['profil'] ?? p['flag'] ?? '').toString();
            if (flag == 'mobile_app_delivery_person_profil') return true;
          }
        }
      }
    } catch (_) {/* read failures fall through to false */}
    return false;
  }

  // ────────────────────────────────────────────────────────────────────────
  // Internal — message intake + UI surfacing + claim call
  // ────────────────────────────────────────────────────────────────────────

  static Future<void> _handleIncoming(
    RemoteMessage message,
    GlobalKey<NavigatorState> navigatorKey,
    Future<String?> Function() getCurrentUserId,
  ) async {
    final payload = DeadHandAlertPayload.tryParse(message.data);
    if (payload == null) return; // not a dead-hand message — ignore.

    // Only one alert at a time — if a second broadcast lands while the
    // courier is still deciding, drop it. (The cron will re-broadcast
    // wider on its next round.)
    if (_alertVisible) return;

    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      debugPrint('[dead-hand] navigator not yet available, dropping alert');
      return;
    }

    _alertVisible = true;
    bool accepted = false;
    try {
      accepted = await DeadHandAlertScreen.show(navigator, payload);
    } finally {
      _alertVisible = false;
    }

    if (!accepted) {
      debugPrint('[dead-hand] declined / timed out — order=${payload.orderId}');
      return;
    }

    final userId = await getCurrentUserId();
    if (userId == null || userId.isEmpty) {
      _snack(navigator, 'Connexion requise pour prendre la course.');
      return;
    }

    await _callClaimApi(navigator, payload.orderId, userId);
  }

  static Future<void> _callClaimApi(
    NavigatorState navigator,
    String orderId,
    String userId,
  ) async {
    try {
      final response = await postWithDio(
        _claimEndpoint,
        body: {'order_id': orderId, 'user_id': userId},
      );

      if (response.success) {
        _snack(navigator, '✅ Course attribuée — bonne livraison !');
      } else {
        // Server returns 409 with verdict.to_dict() on race-loss /
        // not-broadcasting / order-not-found — surface a clear msg.
        final raw = response.raw;
        String reason = response.message ?? 'Course indisponible.';
        if (raw is Map<String, dynamic>) {
          final detail = raw['detail'];
          if (detail is Map<String, dynamic>) {
            final outcome = detail['outcome']?.toString();
            switch (outcome) {
              case 'already_claimed':
                reason = 'Trop tard — un autre livreur a pris la course.';
                break;
              case 'not_broadcasting':
                reason = 'La course n\'est plus en attente.';
                break;
              case 'order_not_found':
                reason = 'Commande introuvable.';
                break;
            }
          }
        }
        _snack(navigator, reason);
      }
    } catch (e) {
      debugPrint('[dead-hand] claim API call failed: $e');
      _snack(navigator, 'Erreur réseau — réessayez.');
    }
  }

  static void _snack(NavigatorState navigator, String message) {
    final ctx = navigator.context;
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    messenger?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }
}
