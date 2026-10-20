/// The three delivery pushes of the live tracking (`delivery_assigned`,
/// `delivery_closed`, `delivery_progress`) and the retired tracking pages.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/delivery/business/interactors/DeliveryController.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/DeliveryApiService.dart';
import 'package:eblood_bank_mak_app/delivery/dispatch/delivery_call_notifications.dart';
import 'package:eblood_bank_mak_app/delivery/dispatch/delivery_call_payload.dart';
import 'package:eblood_bank_mak_app/delivery/dispatch/delivery_call_service.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/delivery_sheet.dart';

Map<String, dynamic> _assigned({String id = 'd1'}) => {'type': 'delivery_assigned', 'delivery_id': id};

Map<String, dynamic> _closed(String reason, {String id = 'd1'}) =>
    {'type': 'delivery_closed', 'delivery_id': id, 'reason': reason};

Map<String, dynamic> _progress({String audience = 'buyer', String id = 'd1', String event = 'picked_up'}) => {
      'type': 'delivery_progress',
      'delivery_id': id,
      'phase': 'picked_up_from_blood_bank',
      'event': event,
      'audience': audience,
    };

class _Fakes {
  final opened = <String>[]; // the courier's sheet
  final sheets = <(String, DeliverySheetRole)>[];
  final closed = <(String, String?)>[];
  bool courier = true;

  late final service = DeliveryCallService(
    ring: (_, __) async {},
    silence: (_) async {},
    isCourier: () => courier,
    openActiveDelivery: (_, id) => opened.add(id),
    openSheet: (_, id, role) => sheets.add((id, role)),
    closeSheet: (id, {message}) => closed.add((id, message)),
  );
}

/// Counts the reloads the home cards would do.
class _CountingIncoming extends IncomingDeliveriesController {
  _CountingIncoming(this.loads) : super(DeliveryApiService(), 'h1', 'u1');
  final List<String> loads;

  @override
  Future<void> loadIncomingDeliveries() async => loads.add('incoming');
}

class _CountingOutgoing extends OutgoingDeliveriesController {
  _CountingOutgoing(this.loads) : super(DeliveryApiService());
  final List<String> loads;

  @override
  Future<void> loadOutgoingDeliveries() async => loads.add('outgoing');
}

Future<_Fakes> _app(WidgetTester tester, {bool withNavigator = true}) async {
  final key = GlobalKey<NavigatorState>();
  final fakes = _Fakes();
  fakes.service.bindNavigator(key);
  if (withNavigator) await tester.pumpWidget(MaterialApp(navigatorKey: key, home: const Scaffold()));
  return fakes;
}

void main() {
  group('payloads', () {
    test('delivery_assigned', () {
      expect(DeliveryAssigned.tryParse(_assigned())!.deliveryId, 'd1');
      expect(DeliveryAssigned.tryParse(_assigned(id: '')), isNull);
      expect(DeliveryAssigned.tryParse(_closed('cancelled')), isNull);
    });

    test('delivery_closed picks the message by reason', () {
      expect(DeliveryClosed.tryParse(_closed('cancelled'))!.messageKey, 'delivery_cancelled_by_admin');
      expect(DeliveryClosed.tryParse(_closed('unassigned'))!.messageKey, 'delivery_reassigned');
      expect(DeliveryClosed.tryParse({'type': 'delivery_closed', 'delivery_id': 'd1'})!.messageKey, 'delivery_reassigned');
      expect(DeliveryClosed.tryParse(_closed('cancelled', id: '')), isNull);
    });

    test('delivery_progress: only a seller audience is a seller', () {
      final seller = DeliveryProgress.tryParse(_progress(audience: 'seller', event: 'at_blood_bank'))!;
      expect(seller.deliveryId, 'd1');
      expect(seller.event, 'at_blood_bank');
      expect(seller.isSeller, isTrue);
      expect(DeliveryProgress.tryParse(_progress())!.isSeller, isFalse);
      expect(DeliveryProgress.tryParse({'type': 'delivery_progress', 'delivery_id': 'd1'})!.isSeller, isFalse);
      expect(DeliveryProgress.tryParse({..._progress(), 'delivery_id': ''}), isNull);
    });

    test('the call parsers do not take the new pushes', () {
      for (final data in [_assigned(), _closed('cancelled'), _progress()]) {
        expect(DeliveryCallPayload.tryParse(data), isNull);
        expect(DeliveryCallClosed.tryParse(data), isNull);
      }
    });
  });

  group('delivery_assigned', () {
    testWidgets('opens the courier sheet, once', (tester) async {
      final f = await _app(tester);
      await f.service.handle(_assigned());
      expect(f.opened, ['d1']);
      expect(f.sheets, isEmpty);
    });

    testWidgets('does nothing for a non-courier account or without a screen', (tester) async {
      final f = await _app(tester);
      f.courier = false;
      await f.service.handle(_assigned());
      expect(f.opened, isEmpty);

      final bare = await _app(tester, withNavigator: false);
      await bare.service.handle(_assigned());
      expect(bare.opened, isEmpty);
    });

    testWidgets('a tapped notification opens it the same way', (tester) async {
      final f = await _app(tester);
      await f.service.handle(_assigned(), fromTap: true);
      expect(f.opened, ['d1']);
    });
  });

  group('delivery_closed', () {
    testWidgets('cancelled closes the delivery with the admin message', (tester) async {
      final f = await _app(tester);
      await f.service.handle(_closed('cancelled'));
      expect(f.closed, [('d1', 'delivery_cancelled_by_admin')]);
    });

    testWidgets('unassigned closes it with the reassigned message', (tester) async {
      final f = await _app(tester);
      await f.service.handle(_closed('unassigned'));
      expect(f.closed, [('d1', 'delivery_reassigned')]);
    });

    testWidgets('closes even without a screen to show anything on', (tester) async {
      final f = await _app(tester, withNavigator: false);
      await f.service.handle(_closed('unassigned'));
      expect(f.closed, [('d1', 'delivery_reassigned')]);
    });
  });

  group('delivery_progress', () {
    testWidgets('a push that was not tapped changes nothing', (tester) async {
      final f = await _app(tester);
      await f.service.handle(_progress(audience: 'seller'));
      expect(f.sheets, isEmpty);
      expect(f.opened, isEmpty);
    });

    testWidgets('a tap opens the sheet as seller or buyer per audience', (tester) async {
      final f = await _app(tester);
      await f.service.handle(_progress(audience: 'seller', event: 'at_blood_bank'), fromTap: true);
      await f.service.handle(_progress(audience: 'buyer', id: 'd2'), fromTap: true);
      await f.service.handle(_progress(audience: '', id: 'd3'), fromTap: true);
      expect(f.sheets, [
        ('d1', DeliverySheetRole.seller),
        ('d2', DeliverySheetRole.buyer),
        ('d3', DeliverySheetRole.buyer),
      ]);
      expect(f.opened, isEmpty);
    });

    testWidgets('a push, tapped or not, reloads the home cards of the side it was sent to', (tester) async {
      final loads = <String>[];
      final key = GlobalKey<NavigatorState>();
      final f = _Fakes()..service.bindNavigator(key);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          incomingDeliveriesProvider.overrideWith((ref) => _CountingIncoming(loads)),
          outgoingDeliveriesProvider.overrideWith((ref) => _CountingOutgoing(loads)),
        ],
        child: MaterialApp(navigatorKey: key, home: const Scaffold()),
      ));

      await f.service.handle(_progress(audience: 'seller'));
      expect(loads, ['outgoing']);
      await f.service.handle(_progress(audience: 'buyer'));
      expect(loads, ['outgoing', 'incoming']);
      expect(f.sheets, isEmpty, reason: 'a push seen in the foreground opens nothing');

      await f.service.handle(_progress(audience: 'seller'), fromTap: true);
      expect(loads, ['outgoing', 'incoming', 'outgoing']);
      expect(f.sheets, [('d1', DeliverySheetRole.seller)]);
    });

    testWidgets('a cold start tap waits for the app to build its screen', (tester) async {
      final key = GlobalKey<NavigatorState>();
      final f = _Fakes()..service.bindNavigator(key);
      final done = f.service.handle(_progress(audience: 'seller'), fromTap: true);
      await tester.pump(const Duration(milliseconds: 300));
      expect(f.sheets, isEmpty);

      await tester.pumpWidget(MaterialApp(navigatorKey: key, home: const Scaffold()));
      await tester.pump(const Duration(milliseconds: 300));
      await done;
      expect(f.sheets, [('d1', DeliverySheetRole.seller)]);
    });
  });

  test('the background isolate ignores the new pushes', () async {
    var touched = 0;
    for (final data in [_assigned(), _closed('cancelled'), _progress()]) {
      await handleDeliveryCallData(
        data,
        isCourier: () async => true,
        ring: (_, __) async => touched++,
        silence: (_) async => touched++,
      );
    }
    expect(touched, 0);
  });

  test('the two old tracking pages are gone and nothing under lib/ mentions them', () {
    for (final name in ['ActiveDeliveryTrackingPage', 'HospitalDeliveryTrackingPage']) {
      expect(File('lib/delivery/ui/pages/$name.dart').existsSync(), isFalse, reason: name);
    }
    final users = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) {
      final text = f.readAsStringSync();
      return text.contains('ActiveDeliveryTrackingPage') || text.contains('HospitalDeliveryTrackingPage');
    }).map((f) => f.path);
    expect(users, isEmpty);
  });
}
