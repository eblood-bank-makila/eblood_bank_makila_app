/// Dead-hand alerts reach a courier only while the device is subscribed to
/// the `delivery_person` FCM topic. These tests pin that the subscription
/// follows the login session, not just the account found at app start.
library;

import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eblood_bank_mak_app/orders/dead_hand/dead_hand_service.dart';

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

const _courierProfiles = [
  {'profil': 'mobile_app_delivery_person_profil'},
];
const _customerProfiles = [
  {'profil': 'mobile_app_customer_profil'},
];

void main() {
  late Directory tempDir;
  late List<bool> topicCalls; // true = subscribe, false = unsubscribe
  late VoidCallback stopWatching;

  void watch() => stopWatching = DeadHandService.watchSession(
        navigatorKey: GlobalKey<NavigatorState>(),
        getCurrentUserId: () async => 'courier-1',
      );

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('eblood_dead_hand_test');
    PathProviderPlatform.instance = _TempPathProvider(tempDir.path);
    await GetStorage.init();
  });

  setUp(() async {
    await GetStorage().erase();
    topicCalls = [];
    DeadHandService.setTopic = (subscribe) async => topicCalls.add(subscribe);
  });

  tearDown(() async {
    stopWatching();
    await DeadHandService.detach();
  });

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('a courier logged in at start subscribes at once', () async {
    await GetStorage().write('user_profiles', _courierProfiles);

    watch();
    await pumpEventQueue();

    expect(topicCalls, [true]);
  });

  test('a non-courier account never subscribes', () async {
    await GetStorage().write('user_profiles', _customerProfiles);

    watch();
    await pumpEventQueue();

    expect(topicCalls, isEmpty);
  });

  test('a courier logging in after start subscribes', () async {
    watch();
    await pumpEventQueue();
    expect(topicCalls, isEmpty);

    await GetStorage().write('user_profiles', _courierProfiles);
    await pumpEventQueue();

    expect(topicCalls, [true]);
  });

  test('a profile rewrite for the same courier does not resubscribe',
      () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    watch();
    await pumpEventQueue();

    await GetStorage().write('user_profiles', _courierProfiles);
    await pumpEventQueue();

    expect(topicCalls, [true]);
  });

  test('logout unsubscribes, and the next courier login subscribes again',
      () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    watch();
    await pumpEventQueue();

    await GetStorage().remove('user_profiles');
    await pumpEventQueue();
    expect(topicCalls, [true, false]);

    await GetStorage().write('user_profiles', _courierProfiles);
    await pumpEventQueue();
    expect(topicCalls, [true, false, true]);
  });

  test('a customer logging in after a courier unsubscribes', () async {
    await GetStorage().write('user_profiles', _courierProfiles);
    watch();
    await pumpEventQueue();

    await GetStorage().write('user_profiles', _customerProfiles);
    await pumpEventQueue();

    expect(topicCalls, [true, false]);
  });
}
