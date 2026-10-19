/// The ringing part of a courier call: an insistent heads-up notification
/// (FLAG_INSISTENT repeats the ringtone until it is cancelled or tapped).
/// Used in the foreground too, so the phone rings while the call screen is
/// up. Play policy: no full-screen intent (Android 14+ reserves it for
/// calling/alarm apps).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';

import 'courier_profile.dart';

import 'delivery_call_payload.dart';

const _channel = AndroidNotificationChannel(
  'delivery_calls',
  'Appels de livraison',
  description: 'Sonne quand une livraison de sang vous est proposée.',
  importance: Importance.max,
  playSound: true,
  sound: UriAndroidNotificationSound('content://settings/system/ringtone'),
  enableVibration: true,
);

const _flagInsistent = 4; // android.app.Notification.FLAG_INSISTENT

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
bool _ready = false;

/// Stable per-delivery id so `delivery_call_closed` cancels the right one.
int notificationIdFor(String deliveryId) => deliveryId.hashCode & 0x7fffffff;

Future<void> _ensureReady({void Function(NotificationResponse)? onTap}) async {
  if (_ready && onTap == null) return;
  await _plugin.initialize(
    const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    onDidReceiveNotificationResponse: onTap,
  );
  await _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);
  _ready = true;
}

/// Foreground init: also routes a tap on the notification to [onTap] with
/// the call's push data.
Future<void> initDeliveryCallNotifications(void Function(Map<String, dynamic> data) onTap) =>
    _ensureReady(onTap: (response) {
      final raw = response.payload;
      if (raw == null || raw.isEmpty) return;
      try {
        onTap(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      } catch (_) {/* malformed payload: ignore */}
    });

Future<void> ringDeliveryCall(DeliveryCallPayload call, Map<String, dynamic> data) async {
  await _ensureReady();
  final left = call.timeLeft();
  if (left == Duration.zero) return;
  final title = call.isUrgent ? '🚨 Livraison urgente à prendre' : '📦 Nouvelle livraison à prendre';
  final km = call.kmToBloodBank == null ? '' : ' · à ${call.kmToBloodBank!.toStringAsFixed(1)} km';
  await _plugin.show(
    notificationIdFor(call.deliveryId),
    title,
    '${call.bloodBankName} → ${call.hospitalName}$km',
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        playSound: true,
        sound: _channel.sound,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        additionalFlags: Int32List.fromList([_flagInsistent]),
        timeoutAfter: left.inMilliseconds,
        autoCancel: true,
        visibility: NotificationVisibility.public,
      ),
    ),
    payload: jsonEncode(data),
  );
}

Future<void> silenceDeliveryCall(String deliveryId) async {
  await _ensureReady();
  await _plugin.cancel(notificationIdFor(deliveryId));
}

/// Ring a call only for an activated courier on this phone (a logged-out
/// or switched account must stay quiet); a close always silences.
Future<void> handleDeliveryCallData(
  Map<String, dynamic> data, {
  required Future<bool> Function() isCourier,
  required Future<void> Function(DeliveryCallPayload call, Map<String, dynamic> data) ring,
  required Future<void> Function(String deliveryId) silence,
}) async {
  final closed = DeliveryCallClosed.tryParse(data);
  if (closed != null) return silence(closed.deliveryId);
  final call = DeliveryCallPayload.tryParse(data);
  if (call != null && await isCourier()) return ring(call, data);
}

/// Background isolate entry (registered in main.dart): ring or silence.
@pragma('vm:entry-point')
Future<void> deliveryCallBackgroundHandler(RemoteMessage message) async {
  try {
    await handleDeliveryCallData(
      Map<String, dynamic>.from(message.data),
      isCourier: () async {
        await GetStorage.init(); // fresh isolate: storage not loaded yet
        return isActivatedCourier();
      },
      ring: ringDeliveryCall,
      silence: silenceDeliveryCall,
    );
  } catch (e) {
    debugPrint('[delivery-call] background handling failed: $e');
  }
}

/// Payload of the call notification that cold-started the app, if any
/// (flutter_local_notifications does not deliver that tap to the callback).
Future<Map<String, dynamic>?> deliveryCallLaunchPayload() async {
  try {
    await _ensureReady();
    final details = await _plugin.getNotificationAppLaunchDetails();
    final raw = details?.didNotificationLaunchApp == true ? details?.notificationResponse?.payload : null;
    if (raw == null || raw.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  } catch (_) {
    return null;
  }
}
