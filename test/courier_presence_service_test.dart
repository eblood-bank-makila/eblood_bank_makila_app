/// Courier presence: the admin console shows a courier "En ligne" only if
/// the app pinged `PUT /eblood-connect/delivery-assignment/presence` within
/// the last 3 minutes. These tests pin when the app pings and when it says
/// it is going offline.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eblood_bank_mak_app/delivery/business/service/courier_presence_service.dart';
import 'package:eblood_bank_mak_app/delivery/dispatch/courier_profile.dart';

class _TempPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _TempPathProvider(this.path);
  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

class _FakeTimer implements Timer {
  bool cancelled = false;
  @override
  void cancel() => cancelled = true;
  @override
  bool get isActive => !cancelled;
  @override
  int get tick => 0;
}

const _courierProfiles = [
  {'profil': 'mobile_app_delivery_person_profil'},
];
const _customerProfiles = [
  {'profil': 'mobile_app_customer_profil'},
];

/// Records every presence call and drives the injected periodic timer.
class _Harness {
  final calls = <bool>[];
  final bodies = <Map<String, dynamic>>[];
  Map<String, double>? position;
  int tokenRegistrations = 0;
  int status = 200;
  Completer<int?>? hold;
  Duration? interval;
  void Function(Timer)? onTick;
  _FakeTimer? timer;

  /// « En service »: on unless a test says otherwise.
  final onDuty = ValueNotifier(true);

  late final service = CourierPresenceService(
    isCourier: () => isActivatedCourier() && onDuty.value,
    duty: onDuty,
    locate: () async => position,
    registerToken: () async => tokenRegistrations++,
    send: (body) async {
      calls.add(body['online'] as bool);
      bodies.add(body);
      return hold != null ? hold!.future : status;
    },
    periodic: (every, callback) {
      interval = every;
      onTick = callback;
      return timer = _FakeTimer();
    },
  );

  Future<void> tick() async {
    onTick!(timer!);
    await pumpEventQueue();
  }
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('eblood_presence_test');
    PathProviderPlatform.instance = _TempPathProvider(tempDir.path);
    await GetStorage.init();
  });

  setUp(() async {
    await GetStorage().erase();
  });

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('a non-courier account never pings', () async {
    await GetStorage().write('user_profiles', _customerProfiles);
    final h = _Harness();

    h.service.attach();
    await pumpEventQueue();

    expect(h.calls, isEmpty);
    expect(h.timer, isNull);
  });

  test('a courier pings online at once, then every 60 s', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness();

    h.service.attach();
    await pumpEventQueue();
    expect(h.calls, [true]);
    expect(h.interval, const Duration(seconds: 60));

    await h.tick();
    await h.tick();
    expect(h.calls, [true, true, true]);
  });

  test('a courier logging in after start begins pinging', () async {
    final h = _Harness();
    h.service.attach();
    await pumpEventQueue();
    expect(h.calls, isEmpty);

    await GetStorage().write('user_profiles', _courierProfiles);
    await pumpEventQueue();

    expect(h.calls, [true]);
    expect(h.timer!.isActive, isTrue);
  });

  test('logout sends offline once and stops the timer', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness();
    h.service.attach();
    await pumpEventQueue();

    await GetStorage().remove('user_profiles');
    await pumpEventQueue();

    expect(h.calls, [true, false]);
    expect(h.timer!.cancelled, isTrue);
  });

  test('on duty, the pings go on in the background, without going offline', () async {
    // The position service keeps the app alive: an on-duty courier whose
    // screen fell asleep must stay « En ligne » for the dispatch.
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness();
    h.service.attach();
    await pumpEventQueue();
    final firstTimer = h.timer!;

    h.service.didChangeAppLifecycleState(AppLifecycleState.paused);
    h.service.didChangeAppLifecycleState(AppLifecycleState.detached);
    await h.tick();
    expect(h.calls, [true, true]);
    expect(firstTimer.isActive, isTrue);

    h.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(h.calls, [true, true]); // no second timer, no extra ping
    expect(h.timer, same(firstTimer));
  });

  test('off duty, an activated courier never pings', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness()..onDuty.value = false;

    h.service.attach();
    await pumpEventQueue();

    expect(h.calls, isEmpty);
    expect(h.timer, isNull);
  });

  test('going on duty starts the pings; going off stops them', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness()..onDuty.value = false;
    h.service.attach();
    await pumpEventQueue();

    h.onDuty.value = true;
    await pumpEventQueue();
    expect(h.calls, [true]);
    expect(h.timer!.isActive, isTrue);

    h.onDuty.value = false;
    await pumpEventQueue();
    expect(h.calls, [true, false]); // lands after any ping in flight
    expect(h.timer!.cancelled, isTrue);
  });

  test('a logout answered 409 (delivery in progress) still completes', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness();
    h.service.attach();
    await pumpEventQueue();

    h.status = 409;
    await GetStorage().remove('user_profiles');
    await pumpEventQueue();

    expect(h.calls, [true, false]);
    expect(h.timer!.cancelled, isTrue);

    // The next login starts afresh.
    h.status = 200;
    await GetStorage().write('user_profiles', _courierProfiles);
    await pumpEventQueue();
    expect(h.calls, [true, false, true]);
  });

  test('a login while backgrounded waits for resume', () async {
    final h = _Harness();
    h.service.attach();
    h.service.didChangeAppLifecycleState(AppLifecycleState.paused);

    await GetStorage().write('user_profiles', _courierProfiles);
    await pumpEventQueue();
    expect(h.calls, isEmpty);

    h.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(h.calls, [true]);
  });

  test('404 (no courier record) stops pinging, even on resume', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness()..status = 404;
    h.service.attach();
    await pumpEventQueue();

    expect(h.calls, [true]);
    expect(h.timer!.cancelled, isTrue);

    h.service.didChangeAppLifecycleState(AppLifecycleState.paused);
    h.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(h.calls, [true]);
  });

  test('403 (courier not activated, or suspended) stops pinging', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness()..status = 403;
    h.service.attach();
    await pumpEventQueue();

    expect(h.calls, [true]);
    expect(h.timer!.cancelled, isTrue);

    h.service.didChangeAppLifecycleState(AppLifecycleState.paused);
    h.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(h.calls, [true]);
  });

  test('a new login after a 404 tries again', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness()..status = 404;
    h.service.attach();
    await pumpEventQueue();

    await GetStorage().remove('user_profiles');
    h.status = 200;
    await GetStorage().write('user_profiles', _courierProfiles);
    await pumpEventQueue();

    expect(h.calls, [true, true]);
  });

  test('a tick while a ping is in flight is dropped', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness()..hold = Completer<int?>();
    h.service.attach();
    await pumpEventQueue();

    await h.tick();
    await h.tick();
    expect(h.calls, [true]);

    h.hold!.complete(200);
    h.hold = null;
    await pumpEventQueue();
    await h.tick();
    expect(h.calls, [true, true]);
  });

  test('offline waits for an in-flight ping so it lands last', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness()..hold = Completer<int?>();
    h.service.attach();
    await pumpEventQueue();

    await GetStorage().remove('user_profiles'); // logout
    await pumpEventQueue();
    expect(h.calls, [true]);

    final inFlight = h.hold!;
    h.hold = null;
    inFlight.complete(200);
    await pumpEventQueue();
    expect(h.calls, [true, false]);
  });

  test('a failing call is swallowed and the next tick still pings', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    var fail = true;
    final calls = <bool>[];
    void Function(Timer)? onTick;
    final timer = _FakeTimer();
    final service = CourierPresenceService(
      isCourier: isActivatedCourier,
      send: (body) async {
        calls.add(body['online'] as bool);
        if (fail) throw const SocketException('offline');
        return 200;
      },
      periodic: (_, callback) {
        onTick = callback;
        return timer;
      },
    );

    service.attach();
    await pumpEventQueue();
    fail = false;
    onTick!(timer);
    await pumpEventQueue();

    expect(calls, [true, true]);
  });

  test('online pings carry the position when known; offline never does', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness()..position = {'lat': -4.32, 'lng': 15.31, 'accuracy': 9};
    h.service.attach();
    await pumpEventQueue();
    expect(h.bodies.single, {'online': true, 'lat': -4.32, 'lng': 15.31, 'accuracy': 9});

    await GetStorage().remove('user_profiles');
    await pumpEventQueue();
    expect(h.bodies.last, {'online': false});
  });

  test('no position: the ping still goes, without coordinates', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    final h = _Harness();
    h.service.attach();
    await pumpEventQueue();
    expect(h.bodies.single, {'online': true});
  });

  test('the push token is registered once per courier login', () async {
    final h = _Harness();
    h.service.attach();
    await pumpEventQueue();
    expect(h.tokenRegistrations, 0); // not a courier yet

    await GetStorage().write('user_profiles', _courierProfiles);
    await pumpEventQueue();
    await h.tick();
    h.service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(h.tokenRegistrations, 1);

    await GetStorage().remove('user_profiles');
    await GetStorage().write('user_profiles', _courierProfiles);
    await pumpEventQueue();
    expect(h.tokenRegistrations, 2);
  });

  test('a courier profile disabled by the server never pings', () async {
    await GetStorage().write('user_profiles', [
      {'profil': 'mobile_app_delivery_person_profil', 'enabled': false},
    ]);
    final h = _Harness();
    h.service.attach();
    await pumpEventQueue();
    expect(h.calls, isEmpty);
  });
}
