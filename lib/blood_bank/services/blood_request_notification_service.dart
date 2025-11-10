import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/blood_request_provider.dart';

/// Service for handling blood request notifications
class BloodRequestNotificationService {
  final FirebaseMessaging _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final WidgetRef? _ref;

  // Notification channel for blood requests
  static const AndroidNotificationChannel _bloodRequestChannel =
      AndroidNotificationChannel(
    'blood_requests_channel',
    'Blood Requests',
    description: 'Notifications for new blood requests',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  BloodRequestNotificationService({
    required FirebaseMessaging fcm,
    required FlutterLocalNotificationsPlugin localNotifications,
    WidgetRef? ref,
  })  : _fcm = fcm,
        _localNotifications = localNotifications,
        _ref = ref;

  /// Initialize the notification service
  Future<void> initialize() async {
    try {
      // Create notification channel for Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_bloodRequestChannel);

      // Request permissions
      await _requestPermissions();

      // Subscribe to blood bank topic
      await _fcm.subscribeToTopic('blood_bank');
      debugPrint('✅ Subscribed to blood_bank topic');

      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Listen for background message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Check for initial message (app opened from terminated state)
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      debugPrint('✅ Blood Request Notification Service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Blood Request Notification Service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Notification permissions granted');
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        debugPrint('⚠️ Provisional notification permissions granted');
      } else {
        debugPrint('❌ Notification permissions denied');
      }
    } catch (e) {
      debugPrint('❌ Error requesting notification permissions: $e');
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📩 Received foreground message: ${message.messageId}');

    final notification = message.notification;
    final data = message.data;

    // Check if it's a blood request notification
    if (data['type'] == 'blood_request' || data['type'] == 'new_blood_request') {
      _showBloodRequestNotification(
        title: notification?.title ?? 'New Blood Request',
        body: notification?.body ?? 'A new blood request has been received',
        data: data,
      );

      // Refresh blood requests list if ref is available
      if (_ref != null) {
        _ref.read(bloodRequestProvider.notifier).fetchBloodRequests(refresh: true);
      }
    }
  }

  /// Handle message tap (background or terminated state)
  void _handleMessageTap(RemoteMessage message) {
    debugPrint('👆 User tapped notification: ${message.messageId}');

    final data = message.data;

    // Navigate to blood request detail if request_id is provided
    if (data['request_id'] != null) {
      // TODO: Navigate to blood request detail page
      debugPrint('📍 Navigate to blood request: ${data['request_id']}');
    }

    // Refresh blood requests list if ref is available
    if (_ref != null) {
      _ref.read(bloodRequestProvider.notifier).fetchBloodRequests(refresh: true);
    }
  }

  /// Show local notification for blood request
  Future<void> _showBloodRequestNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'blood_requests_channel',
        'Blood Requests',
        channelDescription: 'Notifications for new blood requests',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/launcher_icon',
        color: Color(0xFFFF0000), // Red color
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(data),
      );

      debugPrint('✅ Blood request notification shown');
    } catch (e) {
      debugPrint('❌ Error showing blood request notification: $e');
    }
  }

  /// Show notification for new blood request
  Future<void> showNewBloodRequestNotification({
    required String requestId,
    required String urgencyLevel,
    required String bloodType,
    int? units,
  }) async {
    final title = urgencyLevel.toLowerCase() == 'urgent' ||
            urgencyLevel.toLowerCase() == 'critical'
        ? '🚨 URGENT: New Blood Request'
        : '🩸 New Blood Request';

    final body = 'Blood Type: $bloodType${units != null ? ' • $units units' : ''}';

    await _showBloodRequestNotification(
      title: title,
      body: body,
      data: {
        'type': 'blood_request',
        'request_id': requestId,
        'urgency_level': urgencyLevel,
        'blood_type': bloodType,
      },
    );
  }

  /// Show notification for blood request status update
  Future<void> showBloodRequestStatusUpdate({
    required String requestId,
    required String status,
    String? message,
  }) async {
    final title = 'Blood Request Updated';
    final body = message ?? 'Status: ${_formatStatus(status)}';

    await _showBloodRequestNotification(
      title: title,
      body: body,
      data: {
        'type': 'blood_request_update',
        'request_id': requestId,
        'status': status,
      },
    );
  }

  /// Show notification for pickup confirmation
  Future<void> showPickupConfirmationNotification({
    required String requestId,
    required String deliveryPerson,
  }) async {
    const title = '✅ Pickup Confirmed';
    final body = 'Delivery person $deliveryPerson has picked up the blood';

    await _showBloodRequestNotification(
      title: title,
      body: body,
      data: {
        'type': 'pickup_confirmed',
        'request_id': requestId,
      },
    );
  }

  /// Format status for display
  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  /// Unsubscribe from blood bank topic
  Future<void> unsubscribe() async {
    try {
      await _fcm.unsubscribeFromTopic('blood_bank');
      debugPrint('✅ Unsubscribed from blood_bank topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from blood_bank topic: $e');
    }
  }
}

/// Provider for blood request notification service
final bloodRequestNotificationServiceProvider = Provider<BloodRequestNotificationService?>((ref) {
  // This will be initialized in the app startup
  return null;
});

