/// Live delivery tracking: the polyline decoder, the tracking payload model
/// (GET /eblood-connect/delivery-assignment/{id}/tracking) and the hospital
/// status fix on IncomingDelivery.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/delivery/business/model/DeliveryModels.dart';
import 'package:eblood_bank_mak_app/delivery/business/model/delivery_tracking.dart';
import 'package:eblood_bank_mak_app/delivery/business/model/route_polyline.dart';

Map<String, dynamic> _place(String id, String name, double? lat, double? lng) => {
      'id': id,
      'name': name,
      'address': 'Av. $name',
      'phone': '+243 81 000 ${id.length}',
      'lat': lat,
      'lng': lng,
    };

Map<String, dynamic> _leg({int distanceM = 2400, int durationS = 420, bool approximate = false}) => {
      'encoded_polyline': '_p~iF~ps|U_ulLnnqC_mqNvxq`@',
      'distance_m': distanceM,
      'duration_s': durationS,
      'computed_at': '2026-10-20T08:00:00+00:00',
      'origin': {'lat': -4.32, 'lng': 15.31},
      'approximate': approximate,
    };

Map<String, dynamic> _full() => {
      'id': 'd1',
      'identifier': 'del-E8E2D3E1',
      'blood_request_id': 'br1',
      'delivery_phase': 'picked_up_from_blood_bank',
      'assignment_status': 'picked_up',
      'status': 'in_transit',
      'pickup_confirmed_by_seller_at': '2026-10-20T07:55:00',
      'blood_bank': _place('bb1', 'Gombe', -4.30, 15.30),
      'hospital': _place('h1', 'Bolingo', -4.33, 15.27),
      'delivery_person': {'name': 'Jean Mbala', 'phone': '+243 99 111 2222'},
      'courier_position': {'lat': -4.31, 'lng': 15.29, 'accuracy': 12.5},
      'courier_last_seen_at': '2026-10-20T08:00:00Z',
      'route_legs': {
        'to_blood_bank': _leg(distanceM: 800, durationS: 120),
        'to_hospital': _leg(approximate: true),
      },
      'active_leg': 'to_hospital',
      'eta_s': 420,
      'eta_to_hospital_s': 540,
      'bag_count': 2,
      'blood_summary': '2 × AB-',
      'delivery_verification_code': '482913',
    };

void main() {
  group('decodePolyline', () {
    test('decodes the reference string from the encoded-polyline spec', () {
      final pts = decodePolyline('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
      expect(pts, hasLength(3));
      expect(pts[0].lat, closeTo(38.5, 1e-5));
      expect(pts[0].lng, closeTo(-120.2, 1e-5));
      expect(pts[1].lat, closeTo(40.7, 1e-5));
      expect(pts[1].lng, closeTo(-120.95, 1e-5));
      expect(pts[2].lat, closeTo(43.252, 1e-5));
      expect(pts[2].lng, closeTo(-126.453, 1e-5));
    });

    test('empty input gives no points', () => expect(decodePolyline(''), isEmpty));

    test('truncated input gives no points instead of throwing', () {
      expect(decodePolyline('_p~iF~ps|U_ulL'), isEmpty);
      expect(decodePolyline('_'), isEmpty);
    });
  });

  group('DeliveryTracking.fromJson', () {
    test('maps every field of a full payload', () {
      final t = DeliveryTracking.fromJson(_full());
      expect(t.id, 'd1');
      expect(t.identifier, 'del-E8E2D3E1');
      expect(t.bloodRequestId, 'br1');
      expect(t.phase, 'picked_up_from_blood_bank');
      expect(t.assignmentStatus, 'picked_up');
      // offset-less server time is UTC
      expect(t.pickupConfirmedAt, DateTime.utc(2026, 10, 20, 7, 55));
      expect(t.bloodBank.name, 'Gombe');
      expect(t.bloodBank.address, 'Av. Gombe');
      expect(t.bloodBank.lat, -4.30);
      expect(t.hospital.id, 'h1');
      expect(t.hospital.lng, 15.27);
      expect(t.courierName, 'Jean Mbala');
      expect(t.courierPhone, '+243 99 111 2222');
      expect(t.courierPosition, (lat: -4.31, lng: 15.29));
      expect(t.courierLastSeenAt, DateTime.utc(2026, 10, 20, 8));
      expect(t.routeLegs.keys, containsAll(['to_blood_bank', 'to_hospital']));
      expect(t.routeLegs['to_blood_bank']!.distanceM, 800);
      expect(t.routeLegs['to_hospital']!.approximate, isTrue);
      expect(t.routeLegs['to_hospital']!.points, hasLength(3));
      expect(t.activeLeg, 'to_hospital');
      expect(t.etaSeconds, 420);
      expect(t.etaToHospitalSeconds, 540);
      expect(t.verificationCode, '482913');
      expect(t.bagCount, 2);
      expect(t.bloodSummary, '2 × AB-');
      expect(t.isCancelled, isFalse);
      expect(t.isDelivered, isFalse);
    });

    test('currentLeg follows active_leg', () {
      final t = DeliveryTracking.fromJson(_full());
      expect(t.currentLeg, same(t.routeLegs['to_hospital']));
      final other = DeliveryTracking.fromJson({..._full(), 'active_leg': 'to_blood_bank'});
      expect(other.currentLeg!.distanceM, 800);
    });

    test('unknown spots and a missing courier / route do not throw', () {
      final t = DeliveryTracking.fromJson({
        'id': 'd2',
        'delivery_phase': 'awaiting_assignment',
        'blood_bank': _place('bb1', 'Gombe', null, null),
        'hospital': _place('h1', 'Bolingo', null, null),
        'courier_position': null,
        'courier_last_seen_at': null,
        'delivery_person': null,
        'route_legs': {},
        'active_leg': null,
        'eta_s': null,
        'eta_to_hospital_s': null,
        'bag_count': null,
        'delivery_verification_code': null,
      });
      expect(t.bloodBank.lat, isNull);
      expect(t.bloodBank.lng, isNull);
      expect(t.courierPosition, isNull);
      expect(t.courierLastSeenAt, isNull);
      expect(t.courierName, isNull);
      expect(t.routeLegs, isEmpty);
      expect(t.currentLeg, isNull);
      expect(t.etaToHospitalSeconds, isNull);
      expect(t.bagCount, isNull);
      expect(t.bloodSummary, '');
      expect(t.verificationCode, isNull);
      expect(t.positionAge(DateTime.utc(2026, 10, 20)), isNull);
      expect(t.isStale(DateTime.utc(2026, 10, 20)), isFalse);
    });

    test('an empty map and wrongly-typed members do not throw', () {
      expect(() => DeliveryTracking.fromJson({}), returnsNormally);
      final t = DeliveryTracking.fromJson({
        'blood_bank': 'oops',
        'courier_position': {'lat': 'x'},
        'route_legs': {'to_hospital': 'oops', 'to_blood_bank': <String, dynamic>{}},
        'active_leg': 'to_hospital',
        'eta_s': 12.0,
      });
      expect(t.bloodBank.name, isNull);
      expect(t.courierPosition, isNull);
      expect(t.currentLeg, isNull);
      expect(t.routeLegs['to_blood_bank']!.points, isEmpty);
      expect(t.etaSeconds, 12);
    });

    test('phase getters', () {
      expect(DeliveryTracking.fromJson({'delivery_phase': 'cancelled'}).isCancelled, isTrue);
      expect(DeliveryTracking.fromJson({'delivery_phase': 'delivered_and_confirmed'}).isDelivered, isTrue);
    });

    test('isStale flips after 120 s without a position', () {
      final t = DeliveryTracking.fromJson(_full()); // last seen 08:00:00Z
      final at30s = DateTime.utc(2026, 10, 20, 8, 0, 30);
      final at3min = DateTime.utc(2026, 10, 20, 8, 3);
      expect(t.positionAge(at30s), const Duration(seconds: 30));
      expect(t.isStale(at30s), isFalse);
      expect(t.isStale(at3min), isTrue);
    });
  });

  group('IncomingDelivery.fromJson', () {
    test('the hospital reads the delivery phase, not the coarse status', () {
      final d = IncomingDelivery.fromJson({
        'id': 'd1',
        'status': 'in_transit',
        'delivery_phase': 'at_hospital',
      });
      expect(d.status, 'at_hospital');
      expect(d.isAtHospital, isTrue);
    });

    test('falls back to status when the phase is absent', () {
      expect(IncomingDelivery.fromJson({'id': 'd1', 'status': 'in_transit'}).status, 'in_transit');
    });

    test('names come from the nested blood_bank / delivery_person objects', () {
      final d = IncomingDelivery.fromJson({
        'id': 'd1',
        'source_blood_bank_id': 'bb1',
        'delivery_person_id': 'p1',
        'blood_bank': {'id': 'bb1', 'name': 'BB Gombe', 'address': 'Av. de la Justice', 'phone_number': '+243 1'},
        'delivery_person': {'id': 'p1', 'first_name': 'Jean', 'last_name': 'Mbala', 'phone_number': '+243 2'},
      });
      expect(d.bloodBankId, 'bb1');
      expect(d.bloodBankName, 'BB Gombe');
      expect(d.bloodBankAddress, 'Av. de la Justice');
      expect(d.deliveryPersonId, 'p1');
      expect(d.deliveryPersonName, 'Jean Mbala');
      expect(d.deliveryPersonPhone, '+243 2');
    });

    test('the old flat keys still work', () {
      final d = IncomingDelivery.fromJson({
        'id': 'd1',
        'blood_bank_id': 'bb1',
        'blood_bank_name': 'BB Flat',
        'blood_bank_address': 'Flat address',
        'delivery_person_name': 'Flat Courier',
        'delivery_person_phone': '+243 3',
      });
      expect(d.bloodBankName, 'BB Flat');
      expect(d.bloodBankAddress, 'Flat address');
      expect(d.deliveryPersonName, 'Flat Courier');
      expect(d.deliveryPersonPhone, '+243 3');
    });
  });
}
