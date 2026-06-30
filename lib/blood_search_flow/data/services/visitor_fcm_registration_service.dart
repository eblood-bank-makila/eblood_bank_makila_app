/// Visitor FCM token registration service.
///
/// Called from `search_flow_provider.verifyOtp` immediately after the
/// visitor's phone-OTP verification succeeds. At that point we have:
///   - the visitor's auth token (loaded into state.visitorToken via
///     `authService.getAuthToken()` in verifyOtp)
///   - a FirebaseMessaging instance the app has already initialised
///
/// We grab the device's FCM token and POST it to
/// `/eblood-connect/firebase-messaging`. The backend handler upserts a
/// `cfg_fcm_config` row keyed on `(targeted_id=visitor_user_id,
/// fcm_platform)` — that row is the source of truth that
/// `OrderNotificationService` reads from for per-user dispatch.
///
/// Without this step, a visitor user has zero `cfg_fcm_config` rows
/// and `_push_to_users_safe` skips them ("no tokens registered"). They
/// would never receive `order_created`, `delivery_assigned`, etc.
///
/// Failures are swallowed (logged only). A failed FCM register MUST
/// NOT block the visitor from proceeding to payment — the worst case
/// is they don't get push notifications, which is recoverable later
/// (by re-opening the app or via SMS fallback).

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../../apps/config/api/dio_client.dart';

class VisitorFcmRegistrationService {
  VisitorFcmRegistrationService();

  /// Get the device's FCM token and register it with the backend.
  /// Idempotent — calling multiple times upserts the same
  /// (targeted_id, fcm_platform) row server-side.
  ///
  /// Returns `true` if the token was sent and the backend responded
  /// success; `false` otherwise. Never throws.
  Future<bool> registerCurrentDevice() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          debugPrint('🔕 VisitorFcm: getToken() returned null/empty — skipping');
        }
        return false;
      }

      // The `fcm_topic` field on the legacy register endpoint is kept
      // for backward compat — it gets stored on the cfg_fcm_config row
      // but the new dispatch (per-user via cfg_fcm_config) ignores it.
      // Sending "visitor" so anyone introspecting the data later knows
      // which flow registered the token.
      final platform = Platform.isIOS ? 'ios' : 'android';
      final body = <String, dynamic>{
        'platform': platform,
        'fcm_token': token,
        'fcm_topic': 'visitor',
      };

      final response = await postWithDio(
        '/eblood-connect/firebase-messaging',
        body: body,
      );

      if (response.success) {
        if (kDebugMode) {
          debugPrint('🔔 VisitorFcm: token registered (platform=$platform)');
        }
        return true;
      }

      if (kDebugMode) {
        debugPrint(
          '🔕 VisitorFcm: backend returned non-success: ${response.message}',
        );
      }
      return false;
    } catch (e) {
      // Best-effort: never block the visitor flow on a notification
      // registration hiccup.
      if (kDebugMode) {
        debugPrint('🔕 VisitorFcm: registration error (swallowed): $e');
      }
      return false;
    }
  }
}
