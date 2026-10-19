/// Review fixes for the courier call (see delivery_call_test.dart).
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/delivery/business/model/DeliveryModels.dart';
import 'package:eblood_bank_mak_app/delivery/dispatch/delivery_call_notifications.dart';
import 'package:eblood_bank_mak_app/delivery/dispatch/delivery_call_service.dart';

Map<String, dynamic> _call(String id) => {
      'type': 'delivery_call',
      'delivery_id': id,
      'call_ends_at': DateTime.now().toUtc().add(const Duration(minutes: 4)).toIso8601String(),
      'blood_bank_name': 'BB',
      'hospital_name': 'H',
    };

void main() {
  test('server timestamps without a zone are UTC, so a live call is not expired', () {
    // The backend serialises naive UTC (no "Z"); read as local time it looked
    // expired in Kinshasa (UTC+1) and Lubumbashi (UTC+2).
    final inFiveMin = DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String().replaceAll('Z', '');
    final req = PendingDeliveryRequest.fromJson({
      'delivery_id': 'd1',
      'assignment_broadcasted_at': DateTime.now().toUtc().toIso8601String().replaceAll('Z', ''),
      'assignment_timeout_at': inFiveMin,
    });
    expect(req.isExpired, isFalse);
    expect(req.remainingTime.inMinutes, inInclusiveRange(4, 5));
  });

  testWidgets('two calls arriving together show one screen', (tester) async {
    final key = GlobalKey<NavigatorState>();
    final rung = <String>[];
    final service = DeliveryCallService(
      accept: (_) async => null,
      reject: (_) async {},
      ring: (call, _) async => rung.add(call.deliveryId),
      silence: (_) async {},
      isCourier: () => true,
      openActiveDelivery: (_, __) {},
    )..bindNavigator(key);
    await tester.pumpWidget(MaterialApp(navigatorKey: key, home: const Scaffold()));

    service.handle(_call('d1'));
    service.handle(_call('d2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(rung, ['d1']);
    expect(find.byKey(const Key('call-accept')), findsOneWidget);
  });

  group('background isolate', () {
    test('rings only for an activated courier, always silences', () async {
      final rung = <String>[], silenced = <String>[];
      Future<void> run(Map<String, dynamic> data, bool courier) => handleDeliveryCallData(
            data,
            isCourier: () async => courier,
            ring: (call, _) async => rung.add(call.deliveryId),
            silence: (id) async => silenced.add(id),
          );

      await run(_call('d1'), false); // logged out / another account on this phone
      await run(_call('d2'), true);
      await run({'type': 'delivery_call_closed', 'delivery_id': 'd2', 'reason': 'taken'}, false);
      expect(rung, ['d2']);
      expect(silenced, ['d2']);
    });

    test('no other screen replaces the courier background handler', () {
      for (final path in ['lib/apps/widgets/BottomNavBarWidget.dart', 'lib/blood_bank/ui/widgets/BloodBankBottomNavWidget.dart']) {
        expect(File(path).readAsStringSync().contains('onBackgroundMessage'), isFalse, reason: path);
      }
    });
  });

  // Device test 2026-10-19: FCM accepted the call but the A07 showed nothing:
  // main.navigatorKey was never given to GoRouter, so currentState was null
  // and handle() returned before ringing.
  test('the router runs on the app navigator key the call screen uses', () {
    final src = File('lib/apps/config/route/GoRouter.dart').readAsStringSync();
    expect(src.contains('navigatorKey: app_main.navigatorKey'), isTrue);
  });

  test('without a navigator the phone still rings', () async {
    final rung = <String>[];
    final service = DeliveryCallService(
      accept: (_) async => null,
      reject: (_) async {},
      ring: (call, _) async => rung.add(call.deliveryId),
      silence: (_) async {},
      isCourier: () => true,
      openActiveDelivery: (_, __) {},
    )..bindNavigator(GlobalKey<NavigatorState>()); // never mounted
    await service.handle(_call('d9'));
    expect(rung, ['d9']);
  });
}
