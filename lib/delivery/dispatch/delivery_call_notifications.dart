/// The ringing part of a courier call: a silent heads-up notification plus
/// the phone ringtone looped beside it. Android stops a notification's own
/// sound (even FLAG_INSISTENT) as soon as the shade is pulled down, so the
/// ring is played apart and stops when the notification goes (tapped,
/// swiped, cancelled, timed out) or the call ends. Used in the foreground
/// too, so the phone rings while the call screen is up. Play policy: no
/// full-screen intent (Android 14+ reserves it for calling/alarm apps).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:get_storage/get_storage.dart';

import 'courier_profile.dart';

import 'delivery_call_payload.dart';

// New id: a channel's sound cannot change once created, and the old
// 'delivery_calls' one rang by itself (deleted in _ensureReady).
const _channel = AndroidNotificationChannel(
  'delivery_call_alerts',
  'Appels de livraison',
  description: 'Sonne quand une livraison de sang vous est proposée.',
  importance: Importance.max,
  playSound: false,
  enableVibration: true,
);

const _icon = '@drawable/ic_notification';
const _brandRed = Color(0xFFFF0000);

final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
bool _ready = false;

/// Stable per-delivery id so `delivery_call_closed` cancels the right one.
int notificationIdFor(String deliveryId) => deliveryId.hashCode & 0x7fffffff;

Future<void> _ensureReady({void Function(NotificationResponse)? onTap}) async {
  if (_ready && onTap == null) return;
  await _plugin.initialize(
    const InitializationSettings(android: AndroidInitializationSettings(_icon)),
    onDidReceiveNotificationResponse: onTap,
  );
  final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await android?.deleteNotificationChannel('delivery_calls');
  await android?.createNotificationChannel(_channel);
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
  final id = notificationIdFor(call.deliveryId);
  await _plugin.show(
    id,
    title,
    '${call.bloodBankName} → ${call.hospitalName}$km',
    NotificationDetails(
      android: AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        icon: _icon,
        color: _brandRed,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.call,
        playSound: false,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        timeoutAfter: left.inMilliseconds,
        autoCancel: true,
        visibility: NotificationVisibility.public,
      ),
    ),
    payload: jsonEncode(data),
  );
  await _ringWhileShown(id, call);
}

Future<void> silenceDeliveryCall(String deliveryId) async {
  await _ensureReady();
  final id = notificationIdFor(deliveryId);
  if (_ringingId == id) _stopRinging();
  await _plugin.cancel(id);
}

// One ringer per process: the main and the FCM background isolate each have
// their own player, so a new ringer tells the other isolate's to stop.
const _ringerPortName = 'delivery_call_ringer';
ReceivePort? _ringer;
Timer? _ringWatch;
int? _ringingId;

Future<void> _ringWhileShown(int id, DeliveryCallPayload call) async {
  _stopRinging();
  IsolateNameServer.lookupPortByName(_ringerPortName)?.send(null);
  IsolateNameServer.removePortNameMapping(_ringerPortName);
  final port = _ringer = ReceivePort()..listen((_) => _stopRinging());
  IsolateNameServer.registerPortWithName(port.sendPort, _ringerPortName);
  _ringingId = id;
  // shortcut: Ringtone loops on Android 9+ only (older phones ring once), move to a native player if couriers still run them.
  await FlutterRingtonePlayer().playRingtone(looping: true);
  _ringWatch = Timer.periodic(const Duration(seconds: 1), (_) async {
    final live = call.timeLeft() > Duration.zero && await _isShown(id);
    if (!live && _ringer == port) _stopRinging();
  });
}

void _stopRinging() {
  _ringWatch?.cancel();
  _ringWatch = null;
  _ringingId = null;
  final port = _ringer;
  if (port == null) return;
  _ringer = null;
  port.close();
  if (IsolateNameServer.lookupPortByName(_ringerPortName) == port.sendPort) {
    IsolateNameServer.removePortNameMapping(_ringerPortName);
  }
  FlutterRingtonePlayer().stop();
}

Future<bool> _isShown(int id) async {
  try {
    final active = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.getActiveNotifications();
    return active == null || active.any((n) => n.id == id);
  } catch (_) {
    return true; // Android < 6 cannot list notifications: ring until the call ends
  }
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
