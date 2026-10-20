/// « En service / Hors service »: the courier chooses when the dispatch may
/// ring them; while on duty the phone shares its position in the background.
/// These tests pin when the service talks to the server, when it refuses, and
/// what it keeps across restarts and accounts.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
// Transitive dependency of flutter_test (what the framework's own fake time uses).
// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/delivery/business/interactors/DeliveryController.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/DeliveryApiService.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/courier_duty_service.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/active_delivery_sheet_controller.dart';
import 'package:eblood_bank_mak_app/delivery/ui/widgets/duty_switch.dart';

class _TempPathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _TempPathProvider(this.path);
  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

typedef _Fix = ({double lat, double lng, double accuracy});

const _courierProfiles = [
  {'profil': 'mobile_app_delivery_person_profil'},
];

/// Signed in as every login leaves it: the user first, then the profiles.
Future<void> _signIn(String userId) async {
  await GetStorage().write('user_data', {'id': userId});
  await GetStorage().write('user_profiles', _courierProfiles);
}

/// Records the server calls and drives the position stream and the clock.
class _Harness {
  final presence = <Map<String, dynamic>>[];
  final locations = <_Fix>[];

  /// The app's own tracking and the duty stream, in the order they happened.
  final events = <String>[];
  int deliveryResumes = 0;
  int? status = 200;
  Completer<int?>? hold;

  /// Holds every delivery location send until completed.
  Completer<void>? locationHold;
  bool permission = true;
  bool permissionThrows = false;
  bool granted = true;
  bool delivering = false;
  DateTime now = DateTime(2026, 10, 20, 9);
  int subscriptions = 0;
  StreamController<DutyFix>? stream;

  late final service = CourierDutyService(
    sendPresence: (body) async {
      presence.add(body);
      return hold != null ? hold!.future : status;
    },
    sendDeliveryLocation: (lat, lng, accuracy) async {
      locations.add((lat: lat, lng: lng, accuracy: accuracy));
      await locationHold?.future;
    },
    positions: () {
      subscriptions++;
      events.add('subscribe');
      return (stream = StreamController<DutyFix>(onCancel: () => events.add('cancel'))).stream;
    },
    ensurePermission: () async {
      if (permissionThrows) throw StateError('location plugin');
      return permission;
    },
    hasPermission: () async => granted,
    hasActiveDelivery: () => delivering,
    clock: () => now,
    storage: GetStorage(),
    suspendOtherTracking: () => events.add('suspend'),
    resumeOtherTracking: () => events.add('resume'),
    resumeDelivery: () async => deliveryResumes++,
  );

  bool get listening => stream?.hasListener ?? false;

  /// A fix taken at [at] (null: the platform gave no time, so it is taken as now).
  Future<void> fix(double lat, double lng, {double accuracy = 8, DateTime? at}) async {
    stream!.add((lat: lat, lng: lng, accuracy: accuracy, at: at));
    await pumpEventQueue();
  }
}

_Harness _harness() {
  final h = _Harness();
  addTearDown(h.service.dispose);
  return h;
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('eblood_duty_test');
    PathProviderPlatform.instance = _TempPathProvider(tempDir.path);
    await GetStorage.init();
  });

  setUp(() async {
    await GetStorage().erase();
    await _signIn('courier-1');
  });

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('going on duty', () {
    test('starts the position stream, says online and remembers it', () async {
      final h = _harness();

      expect(await h.service.setOnDuty(true), isNull);

      expect(h.service.onDuty, isTrue);
      expect(h.listening, isTrue);
      expect(h.presence, [
        {'online': true},
      ]);
      expect(GetStorage().read('courier_on_duty'), isTrue);
    });

    test("stops the app's own tracking before the duty stream subscribes, and restarts it after", () async {
      // geolocator_android hands every caller its ONE cached stream: the app's
      // 100 m tracking must be gone, or the duty gets it without its foreground service.
      final h = _harness();

      await h.service.setOnDuty(true);
      expect(h.events, ['suspend', 'subscribe']);

      await h.service.setOnDuty(false);
      await pumpEventQueue();
      expect(h.events, ['suspend', 'subscribe', 'cancel', 'resume']);
    });

    test('refused by the server, or without network, stays off with nothing started', () async {
      for (final status in [500, 403, null]) {
        final h = _harness()..status = status;

        expect(await h.service.setOnDuty(true), 'duty_server_error', reason: '$status');

        expect(h.service.onDuty, isFalse);
        expect(h.events, isEmpty);
        expect(GetStorage().read('courier_on_duty'), isNot(isTrue));
      }
    });

    test('already on duty: going on again asks nothing and starts nothing new', () async {
      final h = _harness();
      await h.service.setOnDuty(true);

      expect(await h.service.setOnDuty(true), isNull);

      expect(h.presence, hasLength(1));
      expect(h.subscriptions, 1);
    });

    test('a logout while the online call is out starts nothing and saves nothing', () async {
      final h = _harness()..hold = Completer<int?>();
      final going = h.service.setOnDuty(true);
      await pumpEventQueue();

      await GetStorage().remove('user_profiles');
      h.hold!.complete(200);
      await going;
      await pumpEventQueue();

      expect(h.service.onDuty, isFalse);
      expect(h.subscriptions, 0);
      expect(h.events, isEmpty);
      expect(GetStorage().read('courier_on_duty'), isNot(isTrue));
    });

    test('another user signing in while the online call is out starts nothing', () async {
      final h = _harness()..hold = Completer<int?>();
      final going = h.service.setOnDuty(true);
      await pumpEventQueue();

      await _signIn('courier-2');
      h.hold!.complete(200);
      await going;
      await pumpEventQueue();

      expect(h.service.onDuty, isFalse);
      expect(h.subscriptions, 0);
      expect(GetStorage().read('courier_on_duty'), isNot(isTrue));
    });

    test('without the location permission is refused, with nothing started', () async {
      final h = _harness()..permission = false;

      expect(await h.service.setOnDuty(true), 'duty_location_needed');

      expect(h.service.onDuty, isFalse);
      expect(h.subscriptions, 0);
      expect(h.presence, isEmpty);
      expect(GetStorage().read('courier_on_duty'), isNot(isTrue));
    });
  });

  group('going off duty', () {
    test('stops the stream, says offline and remembers it', () async {
      final h = _harness();
      await h.service.setOnDuty(true);

      expect(await h.service.setOnDuty(false), isNull);

      expect(h.service.onDuty, isFalse);
      expect(h.listening, isFalse);
      expect(h.presence.last, {'online': false});
      expect(GetStorage().read('courier_on_duty'), isFalse);
    });

    test('during a delivery is refused without asking the server', () async {
      final h = _harness();
      await h.service.setOnDuty(true);
      h.delivering = true;

      expect(await h.service.setOnDuty(false), 'duty_finish_delivery_first');

      expect(h.service.onDuty, isTrue);
      expect(h.listening, isTrue);
      expect(h.presence, [
        {'online': true},
      ]);
    });

    test('answered 409 (the server sees a delivery) stays on duty', () async {
      final h = _harness();
      await h.service.setOnDuty(true);
      h.status = 409;

      expect(await h.service.setOnDuty(false), 'duty_finish_delivery_first');

      expect(h.service.onDuty, isTrue);
      expect(h.listening, isTrue);
      expect(GetStorage().read('courier_on_duty'), isTrue);
    });

    test('with no network still goes off: the courier asked for it', () async {
      final h = _harness();
      await h.service.setOnDuty(true);
      h.status = null;

      expect(await h.service.setOnDuty(false), isNull);
      expect(h.service.onDuty, isFalse);
    });
  });

  group('positions', () {
    test('the duty stream: a precise fix every 15 s, moving or not, in a foreground service', () {
      final settings = CourierDutyService.locationSettings;
      expect(settings.accuracy, LocationAccuracy.high);
      expect(settings.distanceFilter, 0); // a courier waiting at the bank stays fresh
      expect(settings.intervalDuration, const Duration(seconds: 15));
      final notification = settings.foregroundNotificationConfig!;
      expect(notification.notificationTitle, 'e-Blood · En service');
      expect(notification.notificationText, 'Position partagée pour les livraisons');
      expect(notification.enableWakeLock, isTrue);
      expect(notification.setOngoing, isTrue);
      // The app's white status-bar icon (kept through shrinking by res/raw/keep.xml), not the launcher.
      expect(notification.notificationIcon.name, 'ic_notification');
      expect(notification.notificationIcon.defType, 'drawable');
    });

    test('a stream that ends is subscribed again once, then duty goes off', () async {
      final h = _harness();
      await h.service.setOnDuty(true);

      await h.stream!.close();
      await pumpEventQueue();
      expect(h.subscriptions, 2);
      expect(h.service.onDuty, isTrue);

      await h.stream!.close();
      await pumpEventQueue();
      expect(h.subscriptions, 2);
      expect(h.service.onDuty, isFalse);
      expect(GetStorage().read('courier_on_duty'), isFalse);
      expect(h.events.last, 'resume');
    });

    test('during a delivery reach the server at most every 15 s', () async {
      final h = _harness()..delivering = true;
      await h.service.setOnDuty(true);

      for (var s = 0; s <= 30; s += 5) {
        await h.fix(s.toDouble(), 15.3); // the latitude says when
        h.now = h.now.add(const Duration(seconds: 5));
      }

      expect(h.locations.map((f) => f.lat), [0, 15, 30]);
    });

    test('during a delivery a send still out holds the next one back', () async {
      final h = _harness()
        ..delivering = true
        ..locationHold = Completer<void>();
      await h.service.setOnDuty(true);

      await h.fix(1, 15.3);
      h.now = h.now.add(const Duration(seconds: 20));
      await h.fix(2, 15.3); // the first is still out
      expect(h.locations.map((f) => f.lat), [1]);

      h.locationHold!.complete();
      h.locationHold = null;
      await pumpEventQueue();
      h.now = h.now.add(const Duration(seconds: 20));
      await h.fix(3, 15.3);
      expect(h.locations.map((f) => f.lat), [1, 3]);
    });

    test('a delivery send that never answers is given up after 15 s', () {
      final h = _harness()
        ..delivering = true
        ..locationHold = Completer<void>(); // never completed: a dead socket
      fakeAsync((async) {
        h.service.setOnDuty(true);
        async.flushMicrotasks();

        h.stream!.add((lat: 1.0, lng: 15.3, accuracy: 8.0, at: null));
        async.flushMicrotasks();
        h.now = h.now.add(const Duration(seconds: 20));
        async.elapse(const Duration(seconds: 14));
        h.stream!.add((lat: 2.0, lng: 15.3, accuracy: 8.0, at: null));
        async.flushMicrotasks();
        expect(h.locations.map((f) => f.lat), [1]);

        async.elapse(const Duration(seconds: 2)); // past the 15 s timeout
        h.now = h.now.add(const Duration(seconds: 20));
        h.stream!.add((lat: 3.0, lng: 15.3, accuracy: 8.0, at: null));
        async.flushMicrotasks();
        expect(h.locations.map((f) => f.lat), [1, 3]);
      });
    });

    test('a fix is as old as the platform says, not as old as its arrival', () async {
      final h = _harness();
      await h.service.setOnDuty(true);

      await h.fix(-4.32, 15.31, at: h.now.subtract(const Duration(minutes: 3)));
      expect(h.service.freshFix, isNull); // a cached position replayed by the stream

      await h.fix(-4.33, 15.31, at: h.now.subtract(const Duration(seconds: 30)));
      expect(h.service.freshFix, {'lat': -4.33, 'lng': 15.31, 'accuracy': 8});
    });

    test('an old fix never reaches the delivery location', () async {
      final h = _harness()..delivering = true;
      await h.service.setOnDuty(true);

      await h.fix(-4.32, 15.31, at: h.now.subtract(const Duration(minutes: 3)));
      expect(h.locations, isEmpty);
    });

    test('the first fresh fix on duty goes to presence at once, only once', () async {
      final h = _harness();
      await h.service.setOnDuty(true);

      await h.fix(-4.30, 15.30, at: h.now.subtract(const Duration(minutes: 3))); // too old to send
      await h.fix(-4.32, 15.31, accuracy: 9);
      h.now = h.now.add(const Duration(seconds: 15));
      await h.fix(-4.33, 15.31);

      expect(h.presence, [
        {'online': true},
        {'online': true, 'lat': -4.32, 'lng': 15.31, 'accuracy': 9},
      ]);
    });

    test('location switched off mid-duty is flagged until fixes come back', () async {
      final h = _harness();
      await h.service.setOnDuty(true);
      var notified = 0;
      h.service.addListener(() => notified++);

      h.stream!.addError(const LocationServiceDisabledException());
      await pumpEventQueue();
      expect(h.service.locationProblem, isTrue);
      expect(h.service.onDuty, isTrue);
      expect(notified, 1);

      await h.fix(-4.32, 15.31);
      expect(h.service.locationProblem, isFalse);
      expect(notified, 2);
    });

    test('without a delivery never reach the delivery location', () async {
      final h = _harness();
      await h.service.setOnDuty(true);

      await h.fix(-4.3, 15.3);
      h.now = h.now.add(const Duration(seconds: 20));
      await h.fix(-4.31, 15.3);

      expect(h.locations, isEmpty);
    });

    test('presence gets the latest fix only while it is at most 2 min old', () async {
      final h = _harness();
      await h.service.setOnDuty(true);
      expect(h.service.freshFix, isNull); // no fix yet

      await h.fix(-4.32, 15.31, accuracy: 9);
      h.now = h.now.add(const Duration(minutes: 2));
      expect(h.service.freshFix, {'lat': -4.32, 'lng': 15.31, 'accuracy': 9});

      h.now = h.now.add(const Duration(seconds: 1));
      expect(h.service.freshFix, isNull);
    });

    test('off duty, no fix is kept for presence', () async {
      final h = _harness();
      await h.service.setOnDuty(true);
      await h.fix(-4.32, 15.31);

      await h.service.setOnDuty(false);
      expect(h.service.freshFix, isNull);
    });
  });

  group('restart', () {
    test('resumes the stream when on duty was saved and location is allowed', () async {
      await GetStorage().write('courier_on_duty', true);
      final h = _harness();

      await h.service.resumeIfNeeded();
      await pumpEventQueue();

      expect(h.service.onDuty, isTrue);
      expect(h.listening, isTrue);
      expect(h.events, ['suspend', 'subscribe']);
      expect(h.deliveryResumes, 1); // the delivery in progress, if any, sends its positions again
    });

    test('without the permission any more goes off duty, without prompting', () async {
      await GetStorage().write('courier_on_duty', true);
      final h = _harness()
        ..granted = false
        ..permission = true; // a prompt would have said yes

      await h.service.resumeIfNeeded();

      expect(h.service.onDuty, isFalse);
      expect(h.subscriptions, 0);
      expect(h.events, isEmpty);
      expect(h.deliveryResumes, 0);
      expect(GetStorage().read('courier_on_duty'), isFalse);
    });

    test('on duty saved but no activated courier signed in: nothing starts', () async {
      await GetStorage().write('courier_on_duty', true);
      await GetStorage().write('user_profiles', [
        {'profil': 'mobile_app_customer_profil'},
      ]);
      final h = _harness();

      await h.service.resumeIfNeeded();
      await pumpEventQueue();

      expect(h.service.onDuty, isFalse);
      expect(h.subscriptions, 0);
      expect(h.events, isEmpty);
      expect(h.deliveryResumes, 0);
    });

    test('off duty saved: nothing starts', () async {
      final h = _harness();

      await h.service.resumeIfNeeded();

      expect(h.service.onDuty, isFalse);
      expect(h.subscriptions, 0);
    });
  });

  group('session', () {
    test('another user signing in turns duty off', () async {
      final h = _harness();
      await h.service.setOnDuty(true);

      await _signIn('courier-2');
      await pumpEventQueue();

      expect(h.service.onDuty, isFalse);
      expect(h.listening, isFalse);
      expect(GetStorage().read('courier_on_duty'), isFalse);
    });

    test('a listener registered after the duty service still sees the logout', () async {
      // GetStorage tells a listener only about the LAST write: a write made
      // while it notifies would hide the logout from the sheet controller.
      final h = _harness();
      await h.service.setOnDuty(true);
      final seen = <Object?>[];
      addTearDown(GetStorage().listenKey('user_profiles', seen.add));

      await GetStorage().remove('user_profiles');
      await pumpEventQueue();

      expect(seen, [null]);
      expect(h.service.onDuty, isFalse);
    });

    test('a logout turns duty off', () async {
      final h = _harness();
      await h.service.setOnDuty(true);

      await GetStorage().remove('user_profiles');
      await pumpEventQueue();

      expect(h.service.onDuty, isFalse);
      expect(h.listening, isFalse);
    });

    test("a same-user profile refresh (AuthApi.getUserProfile) keeps duty on", () async {
      final h = _harness();
      await h.service.setOnDuty(true);

      await GetStorage().write('user_profiles', _courierProfiles);
      await GetStorage().write('user_data', {'id': 'courier-1'});
      await pumpEventQueue();

      expect(h.service.onDuty, isTrue);
      expect(h.listening, isTrue);
    });

    test('the courier profile withdrawn mid-session turns duty off', () async {
      final h = _harness();
      await h.service.setOnDuty(true);

      await GetStorage().write('user_profiles', [
        {'profil': 'mobile_app_customer_profil'},
      ]);
      await pumpEventQueue();

      expect(h.service.onDuty, isFalse);
    });
  });

  group('switch', () {
    Future<void> pumpSwitch(WidgetTester t, CourierDutyService duty, {Future<void> Function()? fixLocation}) =>
        t.pumpWidget(GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('fr', 'FR'),
          fallbackLocale: const Locale('fr', 'FR'),
          home: Scaffold(body: Center(child: DutySwitch(duty: duty, fixLocation: fixLocation))),
        ));

    Future<void> tapSwitch(WidgetTester t) => t.runAsync(() async {
          await t.tap(find.byKey(const Key('duty-switch')));
          await pumpEventQueue();
        });

    bool enabled(WidgetTester t) => t.widget<Switch>(find.byKey(const Key('duty-switch'))).onChanged != null;

    testWidgets('is disabled while the change is on its way', (t) async {
      final h = _harness()..hold = Completer<int?>();
      await pumpSwitch(t, h.service);

      await tapSwitch(t);
      await t.pump();
      expect(enabled(t), isFalse);

      await t.runAsync(() async {
        h.hold!.complete(200);
        await pumpEventQueue();
      });
      await t.pump();
      expect(enabled(t), isTrue);
      expect(h.service.onDuty, isTrue);
    });

    testWidgets('without location, the refusal offers the settings', (t) async {
      final h = _harness()..permission = false;
      var fixes = 0;
      await pumpSwitch(t, h.service, fixLocation: () async => fixes++);

      await tapSwitch(t);
      await t.pump();
      await t.pump(const Duration(milliseconds: 750)); // the SnackBar slides in
      expect(find.text('Autorisez la localisation pour passer en service.'), findsOneWidget);

      await t.tap(find.text('Ouvrir les paramètres'));
      expect(fixes, 1);
    });

    testWidgets('a change that throws leaves the switch usable and says so', (t) async {
      final h = _harness()..permissionThrows = true;
      await pumpSwitch(t, h.service);

      await tapSwitch(t);
      await t.pump();
      await t.pump(const Duration(milliseconds: 750));

      expect(enabled(t), isTrue);
      expect(h.service.onDuty, isFalse);
      expect(find.text('Impossible de passer en service, réessayez.'), findsOneWidget);
    });

    testWidgets('location switched off on duty: says so, and the tap opens the settings', (t) async {
      final h = _harness();
      var fixes = 0;
      await t.runAsync(() async {
        await h.service.setOnDuty(true);
        h.stream!.addError(const LocationServiceDisabledException());
        await pumpEventQueue();
      });
      await pumpSwitch(t, h.service, fixLocation: () async => fixes++);

      expect(find.text('Localisation désactivée'), findsOneWidget);
      await t.tap(find.text('Localisation désactivée'));
      expect(fixes, 1);

      await t.runAsync(() => h.fix(-4.32, 15.31));
      await t.pump();
      expect(find.text('Localisation désactivée'), findsNothing);
      expect(find.text('En service'), findsOneWidget);
    });

    testWidgets('toggles duty on and off and says which', (t) async {
      final h = _harness();
      await pumpSwitch(t, h.service);
      expect(find.text('Hors service'), findsOneWidget);

      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('duty-switch')));
        await pumpEventQueue();
      });
      await t.pump();
      expect(h.service.onDuty, isTrue);
      expect(find.text('En service'), findsOneWidget);

      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('duty-switch')));
        await pumpEventQueue();
      });
      await t.pump();
      expect(h.service.onDuty, isFalse);
      expect(find.text('Hors service'), findsOneWidget);
    });

    testWidgets('a refusal stays on and shows why', (t) async {
      final h = _harness();
      await t.runAsync(() => h.service.setOnDuty(true));
      h.delivering = true;
      await pumpSwitch(t, h.service);

      await t.runAsync(() async {
        await t.tap(find.byKey(const Key('duty-switch')));
        await pumpEventQueue();
      });
      await t.pump();

      expect(h.service.onDuty, isTrue);
      expect(find.text('En service'), findsOneWidget);
      expect(find.text('Terminez la livraison en cours avant de passer hors service.'), findsOneWidget);
    });
  });

  // Last: these build the app-wide singletons.
  group('wiring', () {
    late http.Request sent;

    setUpAll(() {
      dotenv.loadFromString(envString: 'BASE_API_URL=http://api.test');
      // A stored token: getAuthToken returns before its GetStorage fallback.
      FlutterSecureStorage.setMockInitialValues({'auth_token': 'tok'});
    });

    Future<T> server<T>(Future<T> Function() call, {Object? body}) => http.runWithClient(
          call,
          () => MockClient((request) async {
            sent = request;
            return http.Response(jsonEncode(body ?? {'success': true}), 200, headers: {'content-type': 'application/json'});
          }),
        );

    test('the delivery location goes to update-location', () async {
      await server(() => CourierDutyService.instance.sendDeliveryLocation(-4.3, 15.3, 9));

      expect(sent.method, 'PUT');
      expect(sent.url.toString(), 'http://api.test/eblood-connect/delivery-assignment/update-location');
      expect(sent.headers['Authorization'], 'Bearer tok');
      expect(jsonDecode(sent.body), {'lat': -4.3, 'lng': 15.3, 'accuracy': 9});
    });

    test('after a restart, the delivery in progress comes back as the bar', () async {
      final controller = ActiveDeliverySheetController.instance;
      addTearDown(() => controller.closeFor('d9'));

      await server(() => CourierDutyService.instance.resumeDelivery(), body: {
        'data': {'_id': 'd9'},
      });

      expect(sent.url.path, '/eblood-connect/delivery-assignment/active-delivery');
      expect(controller.courierDeliveryId, 'd9');
      expect(controller.minimized, isTrue);
    });

    test("the courier home's active delivery becomes current too", () async {
      final controller = ActiveDeliverySheetController.instance;
      addTearDown(() => controller.closeFor('d8'));

      await server(() => PendingDeliveryRequestController(DeliveryApiService()).loadActiveDelivery(), body: {
        'data': {'_id': 'd8'},
      });

      expect(controller.courierDeliveryId, 'd8');
      expect(controller.showBar, isTrue);
    });
  });
}
