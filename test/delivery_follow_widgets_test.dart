/// The home cards (courier, buyer, seller) open the delivery sheet, and the
/// buyer/seller lists survive the courier-less rows the API now returns.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/delivery/business/interactors/DeliveryController.dart';
import 'package:eblood_bank_mak_app/delivery/business/interactors/delivery_tracking_provider.dart';
import 'package:eblood_bank_mak_app/delivery/business/model/DeliveryModels.dart';
import 'package:eblood_bank_mak_app/delivery/business/model/delivery_tracking.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/DeliveryApiService.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/active_delivery_sheet_controller.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/delivery_sheet.dart';
import 'package:eblood_bank_mak_app/delivery/ui/widgets/ActiveDeliveryWidget.dart';
import 'package:eblood_bank_mak_app/delivery/ui/widgets/IncomingDeliveryWidget.dart';
import 'package:eblood_bank_mak_app/delivery/ui/widgets/OutgoingDeliveryWidget.dart';

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

class _FakeIncoming extends IncomingDeliveriesController {
  _FakeIncoming(List<IncomingDelivery> rows) : super(DeliveryApiService(), 'h1', 'u1') {
    state = rows;
  }

  @override
  Future<void> loadIncomingDeliveries() async {}
}

class _FakeOutgoing extends OutgoingDeliveriesController {
  _FakeOutgoing(List<OutgoingDelivery> rows) : super(DeliveryApiService()) {
    state = rows;
  }

  @override
  Future<void> loadOutgoingDeliveries() async {}
}

/// Rows as the API lists them for a delivery nobody has taken yet.
Map<String, dynamic> _waiting(String id) => {
      'id': id,
      '_id': id,
      'delivery_phase': 'awaiting_acceptance',
      'assignment_status': 'broadcasted',
      'delivery_person': null,
      'blood_bank': {'name': 'cs dannico'},
      'hospital': {'name': 'cs bolingo'},
      'blood_bags': <dynamic>[],
    };

Map<String, dynamic> _withCourier(String id, {String phase = 'en_route_to_hospital', String assignment = 'picked_up', String? pickupAt}) => {
      ..._waiting(id),
      'delivery_phase': phase,
      'assignment_status': assignment,
      'delivery_person': {'first_name': 'Alvic', 'last_name': 'Dalton', 'phone_number': '+243990000000'},
      'pickup_confirmed_by_seller_at': pickupAt,
    };

Future<void> _pump(WidgetTester t, Widget card, List<Override> overrides) async {
  t.view.physicalSize = const Size(900, 2400);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(ProviderScope(
    overrides: [
      deliveryTrackingProvider('d1').overrideWith((ref) => const Stream<DeliveryTracking>.empty()),
      ...overrides,
    ],
    child: GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('fr', 'FR'),
      fallbackLocale: const Locale('fr', 'FR'),
      home: Scaffold(body: SingleChildScrollView(child: card)),
    ),
  ));
  await t.pumpAndSettle(); // the cards slide in
}

Future<void> _settle(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 150));
  }
}

DeliverySheet _openedSheet(WidgetTester t) => t.widget<DeliverySheet>(find.byType(DeliverySheet));

/// The cards style their text with GoogleFonts.ubuntu, which a test host can
/// neither fetch nor find bundled: drop exactly that error.
void _cardTest(String description, Future<void> Function(WidgetTester t) body) {
  testWidgets(description, (t) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final done = Completer<void>();
    runZonedGuarded(() async {
      await body(t);
      if (!done.isCompleted) done.complete();
    }, (error, stack) {
      if ('$error'.contains('GoogleFonts.config.allowRuntimeFetching is false')) return;
      if (!done.isCompleted) done.completeError(error, stack);
    });
    await done.future;
  });
}

final _waitingLabel = find.text("En attente d'un livreur");
final _follow = find.text('Suivre');
final _confirm = find.text('Confirmer la remise des poches');

void main() {
  final controller = ActiveDeliverySheetController.instance;
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The controller watches the session in GetStorage once it opens a sheet.
    tempDir = await Directory.systemTemp.createTemp('eblood_follow_cards_test');
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

  group('buyer (IncomingDeliveryWidget)', () {
    _cardTest('a courier-less row says it waits for a courier, with no courier row and no raw key', (t) async {
      await _pump(t, const IncomingDeliveryWidget(), [
        incomingDeliveriesProvider.overrideWith((ref) => _FakeIncoming([IncomingDelivery.fromJson(_waiting('d1'))])),
      ]);
      expect(_waitingLabel, findsOneWidget);
      expect(find.text('awaiting_acceptance'), findsNothing);
      expect(find.text('Livreur: '), findsNothing);
      expect(find.text('cs dannico'), findsOneWidget);
      expect(_follow, findsOneWidget);
    });

    _cardTest('a row with a courier shows the courier and no waiting label', (t) async {
      await _pump(t, const IncomingDeliveryWidget(), [
        incomingDeliveriesProvider.overrideWith((ref) => _FakeIncoming([IncomingDelivery.fromJson(_withCourier('d1'))])),
      ]);
      expect(find.text('Alvic Dalton'), findsOneWidget);
      expect(_waitingLabel, findsNothing);
    });

    _cardTest('« Suivre » opens the sheet as buyer', (t) async {
      await _pump(t, const IncomingDeliveryWidget(), [
        incomingDeliveriesProvider.overrideWith((ref) => _FakeIncoming([IncomingDelivery.fromJson(_waiting('d1'))])),
      ]);
      await t.tap(_follow);
      await _settle(t);
      expect(_openedSheet(t).role, DeliverySheetRole.buyer);
      expect(_openedSheet(t).deliveryId, 'd1');
    });
  });

  group('seller (OutgoingDeliveryWidget)', () {
    final rows = [
      OutgoingDelivery.fromJson(_waiting('w1')),
      OutgoingDelivery.fromJson(_withCourier('c1', phase: 'at_blood_bank', assignment: 'accepted')),
      OutgoingDelivery.fromJson(_withCourier('p1', pickupAt: '2026-10-20T08:00:00Z')),
    ];

    _cardTest('lists every delivery; only the one to hand over has the confirm button', (t) async {
      await _pump(t, const OutgoingDeliveryWidget(), [outgoingDeliveriesProvider.overrideWith((ref) => _FakeOutgoing(rows))]);
      expect(_follow, findsNWidgets(3));
      expect(_confirm, findsOneWidget);
      expect(_waitingLabel, findsOneWidget);
      expect(find.text('Alvic Dalton'), findsNWidgets(2)); // the waiting row has no courier row
      expect(find.text('Livreur: '), findsNWidgets(2));
    });

    _cardTest('a picked-up delivery is listed with « Suivre » and no confirm button', (t) async {
      final picked = [OutgoingDelivery.fromJson(_withCourier('d1', pickupAt: '2026-10-20T08:00:00Z'))];
      await _pump(t, const OutgoingDeliveryWidget(), [outgoingDeliveriesProvider.overrideWith((ref) => _FakeOutgoing(picked))]);
      expect(_follow, findsOneWidget);
      expect(_confirm, findsNothing);
    });

    _cardTest('nothing to list, nothing shown', (t) async {
      await _pump(t, const OutgoingDeliveryWidget(), [outgoingDeliveriesProvider.overrideWith((ref) => _FakeOutgoing([]))]);
      expect(_follow, findsNothing);
    });

    _cardTest('« Suivre » opens the sheet as seller', (t) async {
      final one = [OutgoingDelivery.fromJson(_waiting('d1'))];
      await _pump(t, const OutgoingDeliveryWidget(), [outgoingDeliveriesProvider.overrideWith((ref) => _FakeOutgoing(one))]);
      await t.tap(_follow);
      await _settle(t);
      expect(_openedSheet(t).role, DeliverySheetRole.seller);
      expect(_openedSheet(t).deliveryId, 'd1');
    });
  });

  group('courier (ActiveDeliveryWidget)', () {
    _cardTest('the card opens the sheet as courier', (t) async {
      final active = ActiveDelivery.fromJson({
        'id': 'd1',
        'delivery_phase': 'en_route_to_blood_bank',
        'assignment_status': 'accepted',
        'blood_bank': {'name': 'cs dannico'},
        'hospital': {'name': 'cs bolingo'},
      });
      await _pump(t, const ActiveDeliveryWidget(), [activeDeliveryProvider.overrideWithValue(active)]);
      await t.tap(find.text('cs dannico'));
      await _settle(t);
      expect(_openedSheet(t).role, DeliverySheetRole.courier);
      expect(_openedSheet(t).deliveryId, 'd1');
    });
  });
}
