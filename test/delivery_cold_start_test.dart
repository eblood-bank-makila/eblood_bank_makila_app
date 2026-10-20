/// A tap on a delivery notification that cold-starts the app lands while the
/// router is still on '/splash'. The splash (3 s, then the auth check) ends
/// with `context.go(...)`, which removes whatever was pushed over it, so the
/// tap has to wait for the router to leave '/splash', '/rbac-loading' and '/intro'.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/delivery/business/interactors/delivery_tracking_provider.dart';
import 'package:eblood_bank_mak_app/delivery/business/model/delivery_tracking.dart';
import 'package:eblood_bank_mak_app/delivery/dispatch/delivery_call_service.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/active_delivery_sheet_controller.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/delivery_sheet.dart';

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

Map<String, dynamic> _progress(String audience) => {
      'type': 'delivery_progress',
      'delivery_id': 'd1',
      'phase': 'at_blood_bank',
      'event': 'at_blood_bank',
      'audience': audience,
    };

Map<String, dynamic> _assigned() => {'type': 'delivery_assigned', 'delivery_id': 'd1'};

/// The app's router as it starts: on '/splash', with its navigator key.
GoRouter _router(GlobalKey<NavigatorState> key) => GoRouter(
      navigatorKey: key,
      initialLocation: '/splash',
      routes: [
        for (final path in ['/splash', '/rbac-loading', '/intro', '/welcome', '/app'])
          GoRoute(path: path, builder: (_, __) => Scaffold(body: Text('page $path'))),
      ],
    );

Future<void> _pumpApp(WidgetTester t, GoRouter router) => t.pumpWidget(ProviderScope(
      overrides: [deliveryTrackingProvider('d1').overrideWith((ref) => const Stream<DeliveryTracking>.empty())],
      child: GetMaterialApp.router(
        translations: AppTranslations(),
        locale: const Locale('fr', 'FR'),
        fallbackLocale: const Locale('fr', 'FR'),
        routerDelegate: router.routerDelegate,
        routeInformationParser: router.routeInformationParser,
        routeInformationProvider: router.routeInformationProvider,
      ),
    ));

/// Lets time pass in small steps, as frames would.
Future<void> _elapse(WidgetTester t, Duration total) async {
  for (var left = total; left > Duration.zero; left -= const Duration(milliseconds: 100)) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  late Directory tempDir;
  final controller = ActiveDeliverySheetController.instance;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The controller watches the session in GetStorage once it opens a sheet.
    tempDir = await Directory.systemTemp.createTemp('eblood_cold_start_test');
    PathProviderPlatform.instance = _TempPathProvider(tempDir.path);
    await GetStorage.init();
  });

  tearDownAll(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() => controller.mapBuilder = (_, __) => const SizedBox.expand());
  tearDown(() {
    controller.closeFor('d1');
    controller.mapBuilder = null;
  });

  testWidgets('a tapped progress push opens the sheet once the router has left the start-up routes, and it stays', (t) async {
    final key = GlobalKey<NavigatorState>();
    final router = _router(key);
    addTearDown(router.dispose);
    final service = DeliveryCallService(isCourier: () => false)..bindNavigator(key);
    await _pumpApp(t, router);
    expect(find.text('page /splash'), findsOneWidget);

    final done = service.handle(_progress('seller'), fromTap: true);
    await _elapse(t, const Duration(seconds: 4)); // the splash is still counting down
    expect(find.byType(DeliverySheet), findsNothing);

    router.go('/rbac-loading?next=/welcome'); // signed in: the RBAC screen comes next
    await _elapse(t, const Duration(seconds: 2));
    expect(find.text('page /rbac-loading'), findsOneWidget);
    expect(find.byType(DeliverySheet), findsNothing);

    router.go('/welcome');
    await _elapse(t, const Duration(seconds: 1));
    await done;
    expect(find.byType(DeliverySheet), findsOneWidget);
    expect(t.widget<DeliverySheet>(find.byType(DeliverySheet)).role, DeliverySheetRole.seller);

    await _elapse(t, const Duration(seconds: 5));
    expect(find.byType(DeliverySheet), findsOneWidget, reason: 'nothing hands over any more');
  });

  testWidgets('the intro route counts as start-up too, and a courier assignment waits the same way', (t) async {
    final key = GlobalKey<NavigatorState>();
    final router = _router(key);
    addTearDown(router.dispose);
    final service = DeliveryCallService(isCourier: () => true)..bindNavigator(key);
    await _pumpApp(t, router);

    router.go('/intro');
    await _elapse(t, const Duration(milliseconds: 500));
    final done = service.handle(_assigned(), fromTap: true);
    await _elapse(t, const Duration(seconds: 3));
    expect(find.byType(DeliverySheet), findsNothing);

    router.go('/app');
    await _elapse(t, const Duration(seconds: 1));
    await done;
    expect(find.byType(DeliverySheet), findsOneWidget);
    expect(t.widget<DeliverySheet>(find.byType(DeliverySheet)).role, DeliverySheetRole.courier);
  });

  testWidgets('a push seen in the foreground does not wait for anything', (t) async {
    final key = GlobalKey<NavigatorState>();
    final router = _router(key);
    addTearDown(router.dispose);
    final opened = <String>[];
    final service = DeliveryCallService(isCourier: () => true, openActiveDelivery: (_, id) => opened.add(id))
      ..bindNavigator(key);
    await _pumpApp(t, router);

    await service.handle(_assigned()); // not a tap, router still on '/splash'
    expect(opened, ['d1']);
  });

  testWidgets('a router that never hands over is waited for 20 s, then the tap opens anyway', (t) async {
    final key = GlobalKey<NavigatorState>();
    final router = _router(key);
    addTearDown(router.dispose);
    final sheets = <String>[];
    final service = DeliveryCallService(openSheet: (_, id, role) => sheets.add('$id:${role.name}'))..bindNavigator(key);
    await _pumpApp(t, router);

    final done = service.handle(_progress('buyer'), fromTap: true);
    await _elapse(t, const Duration(seconds: 19));
    expect(sheets, isEmpty);

    await _elapse(t, const Duration(seconds: 2));
    await done;
    expect(sheets, ['d1:buyer']);
  });
}
