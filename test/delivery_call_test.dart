/// Courier call (Yango-style): the backend rings with `delivery_call` and
/// silences with `delivery_call_closed`. These tests pin the parsing and
/// what the call screen does with the courier's answer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/delivery/dispatch/delivery_call_payload.dart';
import 'package:eblood_bank_mak_app/delivery/dispatch/delivery_call_service.dart';

Map<String, dynamic> _call({String id = 'd1', Duration left = const Duration(minutes: 4)}) => {
      'type': 'delivery_call',
      'delivery_id': id,
      'identifier': 'del-E8E2D3E1',
      'call_ends_at': DateTime.now().toUtc().add(left).toIso8601String(),
      'blood_bank_name': 'BB Gombe',
      'blood_bank_address': 'Av. de la Justice',
      'hospital_name': 'CS Bolingo',
      'hospital_address': 'Kintambo',
      'km_to_blood_bank': '2.4',
      'km_bank_to_hospital': '6.1',
      'bag_count': '2',
      'blood_summary': '2 × O+',
      'priority': 'emergency',
    };

Map<String, dynamic> _closed(String reason, {String id = 'd1'}) =>
    {'type': 'delivery_call_closed', 'delivery_id': id, 'reason': reason};

class _Fakes {
  final rung = <String>[];
  final silenced = <String>[];
  final rejected = <String>[];
  int opened = 0;
  String? acceptResult; // null = success
  bool courier = true;

  late final service = DeliveryCallService(
    accept: (id) async => acceptResult,
    reject: (id) async => rejected.add(id),
    ring: (call, _) async => rung.add(call.deliveryId),
    silence: (id) async => silenced.add(id),
    isCourier: () => courier,
    openActiveDelivery: (_, __) => opened++,
  );
}

Future<(GlobalKey<NavigatorState>, _Fakes)> _app(WidgetTester tester) async {
  final key = GlobalKey<NavigatorState>();
  final fakes = _Fakes();
  fakes.service.bindNavigator(key);
  await tester.pumpWidget(MaterialApp(navigatorKey: key, home: const Scaffold(body: Text('home'))));
  return (key, fakes);
}

void main() {
  group('payload', () {
    test('parses a call with every screen detail', () {
      final call = DeliveryCallPayload.tryParse(_call())!;
      expect(call.deliveryId, 'd1');
      expect(call.bloodBankName, 'BB Gombe');
      expect(call.hospitalName, 'CS Bolingo');
      expect(call.kmToBloodBank, 2.4);
      expect(call.kmBankToHospital, 6.1);
      expect(call.bagCount, 2);
      expect(call.isUrgent, isTrue);
      expect(call.timeLeft().inSeconds, greaterThan(200));
    });

    test('unknown distances stay null instead of breaking the call', () {
      final call = DeliveryCallPayload.tryParse({..._call(), 'km_to_blood_bank': '', 'bag_count': ''})!;
      expect(call.kmToBloodBank, isNull);
      expect(call.bagCount, isNull);
    });

    test('other pushes are not calls', () {
      expect(DeliveryCallPayload.tryParse({'type': 'delivery_accepted', 'delivery_id': 'd1'}), isNull);
      expect(DeliveryCallPayload.tryParse({..._call(), 'call_ends_at': 'nope'}), isNull);
      expect(DeliveryCallClosed.tryParse(_closed('taken'))!.message, 'Course prise par un autre livreur.');
      expect(DeliveryCallClosed.tryParse(_closed('expired'))!.message, 'Appel terminé.');
    });
  });

  testWidgets('a call rings and shows the delivery details', (tester) async {
    final (_, f) = await _app(tester);
    f.service.handle(_call());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(f.rung, ['d1']);
    expect(find.text('BB Gombe'), findsOneWidget);
    expect(find.text('CS Bolingo'), findsOneWidget);
    expect(find.text('à 2.4 km'), findsOneWidget);
    expect(find.text('+ 6.1 km'), findsOneWidget);
    expect(find.text('URGENT'), findsOneWidget);
    expect(find.byKey(const Key('call-accept')), findsOneWidget);
  });

  testWidgets('a tapped call notification shows the same screen', (tester) async {
    final (_, f) = await _app(tester);
    f.service.handle(_call(), fromTap: true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('call-accept')), findsOneWidget);
    expect(f.opened, 0);
  });

  testWidgets('another courier taking it closes the screen and silences the phone', (tester) async {
    final (_, f) = await _app(tester);
    f.service.handle(_call());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await f.service.handle(_closed('taken'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.byKey(const Key('call-accept')), findsNothing);
    expect(find.text('Course prise par un autre livreur.'), findsOneWidget);
    expect(f.silenced, contains('d1'));
    expect(f.opened, 0);
  });

  testWidgets('accepting opens the active delivery', (tester) async {
    final (_, f) = await _app(tester);
    f.service.handle(_call());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('call-accept')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(f.opened, 1);
    expect(f.silenced, contains('d1'));
    expect(find.byKey(const Key('call-accept')), findsNothing);
  });

  testWidgets('a late accept shows « Course déjà prise »', (tester) async {
    final (_, f) = await _app(tester);
    f.acceptResult = 'Course déjà prise.';
    f.service.handle(_call());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('call-accept')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Course déjà prise.'), findsOneWidget);
    expect(f.opened, 0);
  });

  testWidgets('ignoring declines the call', (tester) async {
    final (_, f) = await _app(tester);
    f.service.handle(_call());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('call-decline')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(f.rejected, ['d1']);
    expect(find.byKey(const Key('call-accept')), findsNothing);
  });

  testWidgets('a non-courier account or an ended call never rings', (tester) async {
    final (_, f) = await _app(tester);
    f.courier = false;
    await f.service.handle(_call());
    f.courier = true;
    await f.service.handle(_call(left: const Duration(seconds: -5)));
    await tester.pump();
    expect(f.rung, isEmpty);
    expect(find.byKey(const Key('call-accept')), findsNothing);
  });
}
