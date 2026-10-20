/// Opening, minimizing and closing the delivery sheet: the courier's sheet
/// cannot be dismissed, « Réduire » leaves a bar on every screen, and the
/// delivery ending (or the controller) closes both.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/delivery/business/interactors/delivery_tracking_provider.dart';
import 'package:eblood_bank_mak_app/delivery/business/model/delivery_tracking.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/courier_duty_service.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/active_delivery_bar.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/active_delivery_sheet_controller.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/delivery_sheet.dart';
import 'package:eblood_bank_mak_app/main.dart' show navigatorKey;

const _bank = TrackingPlace(id: 'bb1', name: 'cs dannico', address: 'av. 1', phone: '+243810000001', lat: -4.30, lng: 15.30);
const _hospital = TrackingPlace(id: 'h1', name: 'cs bolingo', address: 'avenue 12', phone: '+243810000002', lat: -4.33, lng: 15.27);

DeliveryTracking _tracking(String phase, {int? eta = 480}) => DeliveryTracking(
      id: 'd1',
      identifier: 'del-E8E2D3E1',
      bloodRequestId: 'br1',
      phase: phase,
      assignmentStatus: 'accepted',
      bloodBank: _bank,
      hospital: _hospital,
      courierName: 'alvic dalton',
      courierPhone: '+243990000000',
      etaSeconds: eta,
      etaToHospitalSeconds: 900,
      bloodSummary: '1 × AB-',
    );

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

final _controller = ActiveDeliverySheetController.instance;
final _sheet = find.byType(DeliverySheet);
final _bar = find.byKey(const Key('active-delivery-bar'));
final _pill = find.text('En route vers la banque');

/// Every subscription to the tracking read gets its own controller; the test pushes updates through [last].
class _Tracking {
  final controllers = <StreamController<DeliveryTracking>>[];
  StreamController<DeliveryTracking> get last => controllers.last;

  Stream<DeliveryTracking> stream() {
    final c = StreamController<DeliveryTracking>();
    controllers.add(c);
    return c.stream;
  }
}

var _taps = 0;

Future<void> _app(WidgetTester t, _Tracking tracking) async {
  t.view.physicalSize = const Size(900, 1800);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  _taps = 0;
  await t.pumpWidget(ProviderScope(
    overrides: [deliveryTrackingProvider('d1').overrideWith((ref) => tracking.stream())],
    child: GetMaterialApp(
      navigatorKey: navigatorKey,
      translations: AppTranslations(),
      locale: const Locale('fr', 'FR'),
      fallbackLocale: const Locale('fr', 'FR'),
      builder: (context, child) => withActiveDeliveryBar(child),
      // The whole page takes taps, so anything the bar covers beyond its own area shows up.
      home: Scaffold(
        body: GestureDetector(
          key: const Key('page'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _taps++,
          child: const SizedBox.expand(),
        ),
      ),
    ),
  ));
}

/// Lets the route animations finish without waiting on the sheet's spinner.
Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

Future<void> _open(WidgetTester t, DeliverySheetRole role, _Tracking tracking, {String phase = 'en_route_to_blood_bank'}) async {
  unawaited(_controller.open(navigatorKey.currentState!, 'd1', role));
  await _settle(t);
  tracking.last.add(_tracking(phase));
  await _settle(t);
}

void main() {
  late Directory tempDir;

  /// Built before any sheet opens, as in the app (presence builds it at start):
  /// its session listener comes before the sheet controller's.
  late CourierDutyService duty;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('eblood_delivery_sheet_test');
    PathProviderPlatform.instance = _TempPathProvider(tempDir.path);
    await GetStorage.init();
    duty = CourierDutyService(
      sendPresence: (_) async => 200,
      sendDeliveryLocation: (_, __, ___) async {},
      positions: () => StreamController<DutyFix>().stream,
      ensurePermission: () async => true,
      hasPermission: () async => true,
      hasActiveDelivery: () => false,
      storage: GetStorage(),
    );
  });

  tearDownAll(() {
    duty.dispose();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  setUp(() => _controller.mapBuilder = (_, __) => const SizedBox.expand());

  tearDown(() {
    _controller.closeFor('d1');
    _controller.mapBuilder = null;
  });

  group('open', () {
    testWidgets('twice for the same delivery and role leaves one sheet on the stack', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      unawaited(_controller.open(navigatorKey.currentState!, 'd1', DeliverySheetRole.courier));
      unawaited(_controller.open(navigatorKey.currentState!, 'd1', DeliverySheetRole.courier));
      await _settle(t);
      tracking.last.add(_tracking('en_route_to_blood_bank'));
      await _settle(t);
      expect(_sheet, findsOneWidget);

      navigatorKey.currentState!.pop(); // a second route would still be up
      await _settle(t);
      expect(_sheet, findsNothing);
    });

    testWidgets('the courier sheet survives back, a tap outside and a swipe down', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);

      await t.binding.handlePopRoute();
      await _settle(t);
      expect(_sheet, findsOneWidget);

      await t.tapAt(const Offset(20, 20));
      await _settle(t);
      expect(_sheet, findsOneWidget);

      await t.fling(_pill, const Offset(0, 600), 2000);
      await _settle(t);
      expect(_sheet, findsOneWidget);
    });

    testWidgets('a follower sheet closes with the cross', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.buyer, tracking);
      expect(_sheet, findsOneWidget);

      await t.tap(find.byKey(const Key('sheet-close')));
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(_controller.showBar, isFalse);
    });

    testWidgets('a follower sheet closes with a swipe down', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.seller, tracking);

      await t.fling(find.text('Livreur en approche'), const Offset(0, 600), 2000);
      await _settle(t);
      expect(_sheet, findsNothing);
    });

    testWidgets('a follower sheet opened over the courier sheet minimizes it instead of losing it', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);

      unawaited(_controller.open(navigatorKey.currentState!, 'd1', DeliverySheetRole.buyer));
      await _settle(t);

      expect(_sheet, findsOneWidget); // the buyer's, not both
      expect(find.byKey(const Key('sheet-close')), findsOneWidget);
      expect(_controller.showBar, isTrue);
    });
  });

  group('minimize and the bar', () {
    testWidgets('« Réduire » swaps the sheet for the bar, and the bar brings the sheet back', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      expect(_bar, findsNothing);
      await _open(t, DeliverySheetRole.courier, tracking);
      expect(_bar, findsNothing); // the sheet is up

      await t.tap(find.byKey(const Key('sheet-minimize')));
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(_bar, findsOneWidget);
      expect(_controller.courierDeliveryId, 'd1');
      expect(_controller.minimized, isTrue);

      await t.tap(_bar);
      await _settle(t);
      expect(_sheet, findsOneWidget);
      expect(_bar, findsNothing);
      expect(_controller.minimized, isFalse);
    });

    testWidgets('the bar shows the ETA and the next stop, from the tracking read', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);
      await t.tap(find.byKey(const Key('sheet-minimize')));
      await _settle(t);

      expect(find.text('Livraison en cours · 8 min'), findsOneWidget); // the sheet's last read carries over
      expect(find.text('Vers cs dannico · position partagée'), findsOneWidget);

      tracking.last.add(_tracking('en_route_to_hospital', eta: 1500));
      await _settle(t);
      expect(find.text('Livraison en cours · 25 min'), findsOneWidget);
      expect(find.text('Vers cs bolingo · position partagée'), findsOneWidget);
    });

    testWidgets('the bar only takes its own area: the page under it stays tappable', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);
      await t.tap(find.byKey(const Key('sheet-minimize')));
      await _settle(t);
      expect(_bar, findsOneWidget);

      final screen = t.getRect(find.byKey(const Key('page')));
      final bar = t.getRect(_bar);
      await t.tapAt(screen.center);
      await t.tapAt(Offset(screen.center.dx, bar.top - 4)); // just above the bar
      await t.tapAt(Offset(bar.left - 4, bar.center.dy)); // beside it
      expect(_taps, 3);
    });

    testWidgets('the delivery ending while minimized closes the bar and says why', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);
      await t.tap(find.byKey(const Key('sheet-minimize')));
      await _settle(t);
      expect(_bar, findsOneWidget);

      tracking.last.add(_tracking('cancelled'));
      await _settle(t);
      expect(_bar, findsNothing);
      expect(_controller.courierDeliveryId, isNull);
      expect(find.text("Livraison annulée par l'administration."), findsOneWidget);
    });
  });

  group('closeFor', () {
    testWidgets('closes the sheet and the courier state and shows the message in the app', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);

      _controller.closeFor('d1', message: 'Livraison réassignée');
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(_bar, findsNothing);
      expect(_controller.courierDeliveryId, isNull);
      expect(_controller.showBar, isFalse);
      expect(find.text('Livraison réassignée'), findsOneWidget);
    });

    testWidgets('closes the bar when the sheet is minimized', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);
      await t.tap(find.byKey(const Key('sheet-minimize')));
      await _settle(t);

      _controller.closeFor('d1', message: 'Fini');
      await _settle(t);
      expect(_bar, findsNothing);
      expect(find.text('Fini'), findsOneWidget);
    });

    testWidgets('leaves a sheet for another delivery alone', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);

      _controller.closeFor('other');
      await _settle(t);
      expect(_sheet, findsOneWidget);
      expect(_controller.courierDeliveryId, 'd1');
    });

    testWidgets('a 403 poll closes the courier sheet as reassigned', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);

      tracking.last.addError(const DeliveryTrackingClosed(forbidden: true));
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(_bar, findsNothing);
      expect(_controller.courierDeliveryId, isNull);
      expect(find.text('Livraison réassignée à un autre livreur.'), findsOneWidget);
    });

    testWidgets("a cancelled delivery closes the sheet with the administration's message", (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.seller, tracking);

      tracking.last.add(_tracking('cancelled'));
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(find.text("Livraison annulée par l'administration."), findsOneWidget);
    });

    testWidgets('the buyer keeps the « Livraison confirmée » message after the sheet closes', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.buyer, tracking, phase: 'at_hospital');

      tracking.last.add(_tracking('delivered_and_confirmed'));
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(find.text('Livraison confirmée'), findsOneWidget);
    });

    testWidgets('a delivered courier delivery closes without a message', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking, phase: 'at_hospital');

      tracking.last.add(_tracking('delivered_and_confirmed'));
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(_bar, findsNothing);
      expect(_controller.courierDeliveryId, isNull);
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('under a dialog', () {
    Future<void> dialog(WidgetTester t) async {
      unawaited(showDialog<void>(
        context: navigatorKey.currentContext!,
        builder: (_) => const AlertDialog(content: Text('dialog')),
      ));
      await _settle(t);
      expect(find.text('dialog'), findsOneWidget);
    }

    /// The dialog is still the top route: one pop closes it and leaves the page.
    Future<void> expectDialogIntact(WidgetTester t) async {
      expect(find.text('dialog'), findsOneWidget);
      navigatorKey.currentState!.pop();
      await _settle(t);
      expect(find.text('dialog'), findsNothing);
      expect(find.byKey(const Key('page')), findsOneWidget);
    }

    testWidgets('closeFor removes the sheet, not the dialog above it, and still says why', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);
      await dialog(t);

      _controller.closeFor('d1', message: 'Livraison réassignée');
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(find.text('Livraison réassignée'), findsOneWidget);
      await expectDialogIntact(t);
    });

    testWidgets('minimize removes the sheet, not the dialog above it', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);
      await dialog(t);

      _controller.minimize();
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(_bar, findsOneWidget);
      await expectDialogIntact(t);
    });
  });

  group('closed from outside', () {
    testWidgets('a courier sheet popped by someone else leaves the bar to reopen it', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);

      navigatorKey.currentState!.pop();
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(_controller.courierDeliveryId, 'd1');
      expect(_bar, findsOneWidget);

      await t.tap(_bar);
      await _settle(t);
      expect(_sheet, findsOneWidget);
    });

    testWidgets('a follower sheet swiped away leaves no bar', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.buyer, tracking);

      navigatorKey.currentState!.pop();
      await _settle(t);
      expect(_bar, findsNothing);
      expect(_controller.courierDeliveryId, isNull);
    });
  });

  group('adopt', () {
    testWidgets('a delivery no sheet shows becomes the bar, without opening the sheet', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);

      _controller.adopt('d1');
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(_bar, findsOneWidget);
      expect(_controller.courierDeliveryId, 'd1');
      expect(_controller.minimized, isTrue);
    });

    testWidgets('leaves the current delivery alone', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);

      _controller.adopt('d2');
      await _settle(t);
      expect(_controller.courierDeliveryId, 'd1');
      expect(_sheet, findsOneWidget);
      expect(_bar, findsNothing);
    });
  });

  group('end message', () {
    testWidgets('is shown once per delivery, until the delivery is opened again', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);

      _controller.closeFor('d1', message: 'one'); // the sheet and the bar can both report the end
      _controller.closeFor('d1', message: 'two');
      await _settle(t);
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsNothing);

      await _open(t, DeliverySheetRole.courier, tracking);
      _controller.closeFor('d1', message: 'three');
      await _settle(t);
      expect(find.text('three'), findsOneWidget);
    });
  });

  group('session change', () {
    var signIns = 0;

    // Signed in as every login leaves it: the user (with its id), then the profiles.
    Future<void> signIn(String userId) async {
      await GetStorage().write('user_data', {'id': userId});
      await GetStorage().write('user_profiles', <dynamic>[]);
    }

    setUp(() => signIn('user-${++signIns}'));

    Future<void> minimized(WidgetTester t, _Tracking tracking) async {
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);
      await t.tap(find.byKey(const Key('sheet-minimize')));
      await _settle(t);
      expect(_bar, findsOneWidget);
    }

    testWidgets('a new login clears the minimized delivery and its bar, without a message', (t) async {
      final tracking = _Tracking();
      await minimized(t, tracking);

      await t.runAsync(() => signIn('someone-else'));
      await _settle(t);
      expect(_bar, findsNothing);
      expect(_controller.courierDeliveryId, isNull);
      expect(_controller.showBar, isFalse);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a same-user profile refresh keeps the delivery and its bar', (t) async {
      final tracking = _Tracking();
      await minimized(t, tracking);

      // AuthApi.getUserProfile rewrites the profiles mid-session, then the user.
      await t.runAsync(() async {
        await GetStorage().write('user_profiles', <dynamic>[]);
        await GetStorage().write('user_data', {'id': 'user-$signIns'});
      });
      await _settle(t);
      expect(_bar, findsOneWidget);
      expect(_controller.courierDeliveryId, 'd1');
    });

    testWidgets('a logout closes the courier sheet that is up', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);

      await t.runAsync(() => GetStorage().remove('user_profiles'));
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(_bar, findsNothing);
      expect(_controller.courierDeliveryId, isNull);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('a logout while on duty still closes the courier sheet', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.courier, tracking);
      await t.runAsync(() => duty.setOnDuty(true));
      expect(duty.onDuty, isTrue);

      await t.runAsync(() => GetStorage().remove('user_profiles'));
      await _settle(t);
      expect(_sheet, findsNothing);
      expect(_controller.courierDeliveryId, isNull);
      expect(duty.onDuty, isFalse);
    });

    testWidgets('a logout closes a follower sheet too', (t) async {
      final tracking = _Tracking();
      await _app(t, tracking);
      await _open(t, DeliverySheetRole.buyer, tracking);

      await t.runAsync(() => GetStorage().remove('user_profiles'));
      await _settle(t);
      expect(_sheet, findsNothing);
    });
  });
}
