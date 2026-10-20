/// « En service / Hors service »: the courier chooses when the dispatch may
/// ring them; while on duty the phone shares its position in the background.
/// These tests pin when the service talks to the server, when it refuses, and
/// what it keeps across restarts and accounts.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/courier_duty_service.dart';
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
  int? status = 200;
  bool permission = true;
  bool granted = true;
  bool delivering = false;
  DateTime now = DateTime(2026, 10, 20, 9);
  int subscriptions = 0;
  StreamController<_Fix>? stream;

  late final service = CourierDutyService(
    sendPresence: (body) async {
      presence.add(body);
      return status;
    },
    sendDeliveryLocation: (lat, lng, accuracy) async => locations.add((lat: lat, lng: lng, accuracy: accuracy)),
    positions: () {
      subscriptions++;
      return (stream = StreamController<_Fix>()).stream;
    },
    ensurePermission: () async => permission,
    hasPermission: () async => granted,
    hasActiveDelivery: () => delivering,
    clock: () => now,
    storage: GetStorage(),
  );

  bool get listening => stream?.hasListener ?? false;

  Future<void> fix(double lat, double lng, {double accuracy = 8}) async {
    stream!.add((lat: lat, lng: lng, accuracy: accuracy));
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
    test('during a delivery reach the server at most every 15 s', () async {
      final h = _harness()..delivering = true;
      await h.service.setOnDuty(true);

      for (var s = 0; s <= 30; s += 5) {
        await h.fix(s.toDouble(), 15.3); // the latitude says when
        h.now = h.now.add(const Duration(seconds: 5));
      }

      expect(h.locations.map((f) => f.lat), [0, 15, 30]);
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

      expect(h.service.onDuty, isTrue);
      expect(h.listening, isTrue);
    });

    test('without the permission any more goes off duty, without prompting', () async {
      await GetStorage().write('courier_on_duty', true);
      final h = _harness()
        ..granted = false
        ..permission = true; // a prompt would have said yes

      await h.service.resumeIfNeeded();

      expect(h.service.onDuty, isFalse);
      expect(h.subscriptions, 0);
      expect(GetStorage().read('courier_on_duty'), isFalse);
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
    Future<void> pumpSwitch(WidgetTester t, CourierDutyService duty) => t.pumpWidget(GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('fr', 'FR'),
          fallbackLocale: const Locale('fr', 'FR'),
          home: Scaffold(body: Center(child: DutySwitch(duty: duty))),
        ));

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
}
