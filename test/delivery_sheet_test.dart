import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/delivery/business/interactors/DeliveryController.dart';
import 'package:eblood_bank_mak_app/delivery/business/interactors/delivery_tracking_provider.dart';
import 'package:eblood_bank_mak_app/delivery/business/model/DeliveryModels.dart';
import 'package:eblood_bank_mak_app/delivery/business/model/delivery_tracking.dart';
import 'package:eblood_bank_mak_app/delivery/business/service/DeliveryApiService.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/delivery_map_view.dart';
import 'package:eblood_bank_mak_app/delivery/ui/sheet/delivery_sheet.dart';
import 'package:eblood_bank_mak_app/delivery/ui/widgets/slide_to_confirm.dart';

const _bank = TrackingPlace(id: 'bb1', name: 'cs dannico', address: "avec'ue", phone: '+243810000001', lat: -4.30, lng: 15.30);
const _hospital = TrackingPlace(id: 'h1', name: 'cs bolingo', address: 'avenue 12', phone: '+243810000002', lat: -4.33, lng: 15.27);
const _leg = TrackingLeg(points: [(lat: -4.31, lng: 15.29), (lat: -4.30, lng: 15.30)], distanceM: 3200, durationS: 480, approximate: false);

DeliveryTracking _tracking(
  String phase, {
  bool pickupConfirmed = false,
  String? courierName = 'alvic dalton',
  DateTime? lastSeen,
  LatLngPoint? position = (lat: -4.31, lng: 15.29),
  int? eta = 480,
  int? etaToHospital = 900,
  bool withRoute = true,
}) =>
    DeliveryTracking(
      id: 'd1',
      identifier: 'del-E8E2D3E1',
      bloodRequestId: 'br1',
      phase: phase,
      assignmentStatus: 'accepted',
      pickupConfirmedAt: pickupConfirmed ? DateTime.utc(2026, 10, 20, 8) : null,
      bloodBank: _bank,
      hospital: _hospital,
      courierName: courierName,
      courierPhone: courierName == null ? null : '+243990000000',
      courierPosition: position,
      courierLastSeenAt: lastSeen,
      routeLegs: withRoute ? const {'to_blood_bank': _leg} : const {},
      activeLeg: withRoute ? 'to_blood_bank' : null,
      etaSeconds: eta,
      etaToHospitalSeconds: etaToHospital,
      verificationCode: '847332',
      bagCount: 1,
      bloodSummary: '1 × AB-',
    );

class _FakeApi extends DeliveryApiService {
  _FakeApi(this.result);
  final ApiResponse<bool> result;
  final calls = <String>[];

  @override
  Future<ApiResponse<bool>> updateDeliveryPhase(String deliveryId, String phase, {LocationInfo? location}) async {
    calls.add('$deliveryId:$phase');
    return result;
  }
}

Widget _host(
  Stream<DeliveryTracking> Function() stream,
  DeliverySheetRole role, {
  DeliveryApiService? api,
  void Function(String?)? onEnded,
}) =>
    ProviderScope(
      overrides: [
        deliveryTrackingProvider('d1').overrideWith((ref) => stream()),
        if (api != null) deliveryApiServiceProvider.overrideWithValue(api),
      ],
      child: GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('fr', 'FR'),
        fallbackLocale: const Locale('fr', 'FR'),
        home: DeliverySheet(
          deliveryId: 'd1',
          role: role,
          mapBuilder: (_, __) => const SizedBox.expand(key: Key('map')),
          onEnded: onEnded,
        ),
      ),
    );

Future<void> _show(WidgetTester t, DeliveryTracking value, DeliverySheetRole role, {DeliveryApiService? api}) async {
  await t.pumpWidget(_host(() => Stream.value(value), role, api: api));
  await t.pump();
  await t.pump();
}

final _code = find.byKey(const Key('handover-code'));
final _knob = find.byKey(const Key('slide-knob'));

/// Location denied: the step still goes out, without a position.
void _denyLocation(WidgetTester t) => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/geolocator'),
      (_) async => 0,
    );

Future<void> _slide(WidgetTester t) async {
  await t.drag(_knob, Offset(t.getSize(find.byType(SlideToConfirm)).width, 0));
  await t.pumpAndSettle();
}

void main() {
  group('courier', () {
    testWidgets('heading to the bank: the arrival slide, no handover code', (t) async {
      await _show(t, _tracking('en_route_to_blood_bank'), DeliverySheetRole.courier);
      expect(find.text('Glisser · Arrivé à la banque'), findsOneWidget);
      expect(find.byKey(const Key('sheet-minimize')), findsOneWidget);
      expect(find.text('En route vers la banque'), findsOneWidget);
      expect(_code, findsNothing);
    });

    testWidgets('heading to the hospital: the handover code is shown', (t) async {
      await _show(t, _tracking('en_route_to_hospital', pickupConfirmed: true), DeliverySheetRole.courier);
      expect(_code, findsOneWidget);
      expect(find.descendant(of: _code, matching: find.text('847332')), findsOneWidget);
      expect(find.text('Glisser · Arrivé à l\'hôpital'), findsOneWidget);
    });

    testWidgets('at the bank before the handover: waiting text, no slide', (t) async {
      await _show(t, _tracking('at_blood_bank'), DeliverySheetRole.courier);
      expect(find.byType(SlideToConfirm), findsNothing);
      expect(find.text('En attente de la remise par la banque…'), findsOneWidget);
    });

    testWidgets('a refused step shows the server message and the slide comes back', (t) async {
      const msg = "La livraison n'est pas encore remise par la banque.";
      final api = _FakeApi(ApiResponse.error(msg, statusCode: 409));
      _denyLocation(t);
      await _show(t, _tracking('en_route_to_blood_bank'), DeliverySheetRole.courier, api: api);
      final start = t.getTopLeft(_knob);

      await _slide(t);

      expect(api.calls, ['d1:at_blood_bank']);
      expect(find.text(msg), findsOneWidget);
      expect(t.getTopLeft(_knob), start);
    });

    testWidgets('an accepted step goes out and the slide stays confirmed through the refresh', (t) async {
      final api = _FakeApi(ApiResponse.success(true));
      _denyLocation(t);
      await _show(t, _tracking('en_route_to_blood_bank'), DeliverySheetRole.courier, api: api);
      final start = t.getTopLeft(_knob);

      await _slide(t);

      expect(api.calls, ['d1:at_blood_bank']);
      expect(find.byType(SnackBar), findsNothing);
      expect(t.getTopLeft(_knob), isNot(start));
    });

    testWidgets('the courier sees the leg ETA, not the trip to the hospital', (t) async {
      await _show(t, _tracking('en_route_to_blood_bank', eta: 480, etaToHospital: 900), DeliverySheetRole.courier);
      expect(find.text('8 min'), findsOneWidget);
      expect(find.text('15 min'), findsNothing);
    });
  });

  group('followers', () {
    testWidgets('buyer at the hospital can confirm reception', (t) async {
      await _show(t, _tracking('at_hospital', pickupConfirmed: true), DeliverySheetRole.buyer);
      final button = find.widgetWithText(FilledButton, 'Confirmer la réception');
      expect(button, findsOneWidget);
      expect(t.widget<FilledButton>(button).onPressed, isNotNull);
      expect(find.byKey(const Key('sheet-close')), findsOneWidget);
      expect(find.byType(SlideToConfirm), findsNothing);
    });

    testWidgets('seller at the bank can confirm the handover', (t) async {
      await _show(t, _tracking('at_blood_bank'), DeliverySheetRole.seller);
      final button = find.widgetWithText(FilledButton, 'Confirmer la remise');
      expect(button, findsOneWidget);
      expect(t.widget<FilledButton>(button).onPressed, isNotNull);
      expect(find.text('Livreur en approche'), findsOneWidget);
    });

    testWidgets('a 3-minute-old position is flagged as stale', (t) async {
      final lastSeen = DateTime.now().toUtc().subtract(const Duration(minutes: 3, seconds: 5));
      await _show(t, _tracking('en_route_to_hospital', pickupConfirmed: true, lastSeen: lastSeen), DeliverySheetRole.buyer);
      expect(find.text('⚠ position il y a 3 min'), findsOneWidget);
    });

    testWidgets('a fresh position reads as live', (t) async {
      final lastSeen = DateTime.now().toUtc().subtract(const Duration(seconds: 8));
      await _show(t, _tracking('en_route_to_hospital', pickupConfirmed: true, lastSeen: lastSeen), DeliverySheetRole.buyer);
      expect(find.textContaining('en direct · il y a'), findsOneWidget);
    });

    testWidgets('the buyer sees the ETA to the hospital', (t) async {
      await _show(t, _tracking('en_route_to_blood_bank', eta: 300, etaToHospital: 900), DeliverySheetRole.buyer);
      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('5 min'), findsNothing);
    });

    testWidgets('no route and no courier position still renders, ETA —', (t) async {
      await _show(
        t,
        _tracking('en_route_to_blood_bank', withRoute: false, position: null, eta: null, etaToHospital: null),
        DeliverySheetRole.buyer,
      );
      expect(find.text('—'), findsOneWidget);
      expect(find.byKey(const Key('map')), findsOneWidget);
    });

    testWidgets('without a courier: waiting pill, no courier card or call', (t) async {
      await _show(
        t,
        _tracking('awaiting_assignment', courierName: null, position: null, withRoute: false, eta: null),
        DeliverySheetRole.buyer,
      );
      expect(find.text("En attente d'un livreur"), findsOneWidget);
      expect(find.text('alvic dalton'), findsNothing);
      expect(find.byKey(const Key('call-courier')), findsNothing);
    });

    testWidgets('with a courier: their card and a call button', (t) async {
      await _show(t, _tracking('en_route_to_hospital', pickupConfirmed: true), DeliverySheetRole.seller);
      expect(find.text('alvic dalton'), findsOneWidget);
      expect(find.byKey(const Key('call-courier')), findsOneWidget);
    });
  });

  group('onEnded fires once', () {
    Future<List<String?>> run(WidgetTester t, void Function(StreamController<DeliveryTracking>) feed) async {
      final ended = <String?>[];
      final ctrl = StreamController<DeliveryTracking>();
      await t.pumpWidget(_host(() => ctrl.stream, DeliverySheetRole.buyer, onEnded: ended.add));
      ctrl.add(_tracking('en_route_to_hospital', pickupConfirmed: true));
      await t.pump();
      feed(ctrl);
      await t.pump();
      await t.pump();
      await ctrl.close();
      return ended;
    }

    testWidgets('cancelled by the admin', (t) async {
      final ended = await run(t, (c) => c..add(_tracking('cancelled'))..add(_tracking('cancelled')));
      expect(ended, ['delivery_cancelled_by_admin']);
    });

    testWidgets('delivered and confirmed', (t) async {
      final ended = await run(t, (c) => c..add(_tracking('delivered_and_confirmed'))..add(_tracking('delivered_and_confirmed')));
      expect(ended, [null]);
    });

    testWidgets('access withdrawn (reassigned)', (t) async {
      final ended = await run(t, (c) => c..addError(const DeliveryTrackingClosed(forbidden: true)));
      expect(ended, ['delivery_reassigned']);
    });
  });

  test('map points: pins and route, nothing invented when unknown', () {
    final full = trackingPoints(_tracking('en_route_to_blood_bank'));
    expect(full, hasLength(5)); // bank, hospital, courier, 2 route points
    final bare = trackingPoints(_tracking('awaiting_assignment', courierName: null, position: null, withRoute: false));
    expect(bare, hasLength(2));
    const unknown = DeliveryTracking(
      id: 'd1',
      identifier: 'del-1',
      bloodRequestId: 'br1',
      phase: 'awaiting_assignment',
      assignmentStatus: 'pending',
      bloodBank: TrackingPlace(),
      hospital: TrackingPlace(),
    );
    expect(trackingPoints(unknown), isEmpty);
  });

  test('every sheet string exists in all five locales', () {
    const keys = [
      'sheet_minimize', 'sheet_navigate', 'map_recenter', 'contact_support', 'call',
      'slide_arrived_bank', 'slide_picked_up', 'slide_leave_for_hospital', 'slide_arrived_hospital', 'slide_busy',
      'waiting_bank_handover', 'waiting_hospital_confirm', 'handover_code_label',
      'live_seconds_ago', 'position_stale_minutes',
      'pill_to_bank', 'pill_to_hospital', 'pill_to_you', 'pill_courier_coming', 'pill_waiting_courier',
      'confirm_receipt', 'confirm_handover', 'delivery_cancelled_by_admin', 'delivery_reassigned',
    ];
    final missing = <String>[];
    for (final entry in AppTranslations().keys.entries) {
      for (final key in keys) {
        final value = entry.value[key];
        if (value == null || value.trim().isEmpty) missing.add('${entry.key}: $key');
      }
    }
    expect(missing, isEmpty);
  });
}
