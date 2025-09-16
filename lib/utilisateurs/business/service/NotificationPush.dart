import 'dart:convert';
import 'dart:io';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PushNotificationService {
  UtilisateurLocalService local;
  final FirebaseMessaging _fcm;
  final AndroidNotificationChannel channel = const AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    // 'This channel is used for important notifications.', // description
    importance: Importance.max,
  );
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  PushNotificationService(this._fcm, this.local);

  _sendUserToken(token) async {
    try {
      String baseUrl = dotenv.env['BASE_URL'] ?? '';
      var tokens=await local.recupererTokenOtp();
      final response = await http.post(Uri.parse("$baseUrl/data/firebase-messaging"),
          headers: {
            "eblood-lockkeys":
            "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31",
            "Authorization": "Bearer $tokens"
          }, body: {
        "platform": Platform.isIOS ? 'ios' : 'android',
        "fcm_token": "$token",
        "fcm_topic": "hopital"
      });
      if (kDebugMode) {
        debugPrint("fcm token saved :${response.body}");
      }
      if (response.statusCode == 200) {
        if (kDebugMode) {
          debugPrint("fcm token saved ::");
        }
      } else {
        if (kDebugMode) {
          debugPrint("fcm token no saved ::");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("fcm err :: $e");
      }
    }
  }

  Future initialise() async {
    //final FlutterLocalNotificationsPlugin
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      if (kDebugMode) {
        print('User granted provisional permission');
      }
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }
    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }
    _fcm.requestPermission();
    // If you want to test the push notification locally,
    // you need to get the token and input to the Firebase console
    // https://console.firebase.google.com/project/YOUR_PROJECT_ID/notification/compose

    _fcm.getToken().then((value) {
      if (kDebugMode) {
        print("FirebaseMessaging token: $value");
      }
      _sendUserToken(value);
    });

    await _fcm.subscribeToTopic('hopital');
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      // If onMessage is triggered with a notification, construct our own
      // local notification to show to users using the created channel.
      if (notification != null && android != null) {
        showFlutterNotification(message);
      }
    });

    //Returns a [Stream] that is called when a user presses a notification message displayed via FCM.
    //A Stream event will be sent if the app has opened from a background state (not terminated).
    //If your app is opened via a notification whilst the app is terminated, see [getInitialMessage].
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Get.to(const NotificationScreen());
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        showFlutterNotification(message);
      }
      if (kDebugMode) {
        print("onMessageOpenedApp ---: ");
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      _sendUserToken(fcmToken);
    }).onError((err) {
      // Error getting token.
    });
  }

  void showFlutterNotification(
    RemoteMessage message,
  ) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    if (notification != null && android != null && !kIsWeb) {
      flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            // channel.description,
            importance: Importance.high,
            playSound: true,
            enableVibration: true,
            icon: '@mipmap/launcher_icon',
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  }
}
