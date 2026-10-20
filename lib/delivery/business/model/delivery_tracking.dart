/// Live tracking payload: GET /eblood-connect/delivery-assignment/{id}/tracking.
/// Every field is parsed defensively — a half-filled payload (unknown
/// coordinates, no courier yet, no route) must still render, never throw.
library;

import 'DeliveryModels.dart' show parseServerTime;
import 'route_polyline.dart';

typedef LatLngPoint = ({double lat, double lng});

class TrackingPlace {
  final String? id, name, address, phone;
  final double? lat, lng;

  const TrackingPlace({this.id, this.name, this.address, this.phone, this.lat, this.lng});

  factory TrackingPlace.fromJson(Object? raw) {
    final j = _map(raw);
    return TrackingPlace(
      id: _str(j['id']),
      name: _str(j['name']),
      address: _str(j['address']),
      phone: _str(j['phone']),
      lat: _num(j['lat'])?.toDouble(),
      lng: _num(j['lng'])?.toDouble(),
    );
  }
}

class TrackingLeg {
  final List<LatLngPoint> points;
  final int distanceM;
  final int durationS;
  final bool approximate;

  const TrackingLeg({
    required this.points,
    required this.distanceM,
    required this.durationS,
    required this.approximate,
  });

  factory TrackingLeg.fromJson(Map<String, dynamic> j) => TrackingLeg(
        points: decodePolyline(_str(j['encoded_polyline']) ?? ''),
        distanceM: _num(j['distance_m'])?.round() ?? 0,
        durationS: _num(j['duration_s'])?.round() ?? 0,
        approximate: j['approximate'] == true,
      );
}

class DeliveryTracking {
  /// No position for this long = the courier's phone has probably lost signal.
  static const staleAfter = Duration(seconds: 120);

  final String id, identifier, bloodRequestId, phase, assignmentStatus;
  final DateTime? pickupConfirmedAt;
  final TrackingPlace bloodBank, hospital;
  final String? courierName, courierPhone;
  final LatLngPoint? courierPosition;
  final DateTime? courierLastSeenAt;
  final Map<String, TrackingLeg> routeLegs;
  final String? activeLeg;

  /// ETA of the active leg / of the whole trip to the hospital (what the
  /// buyer sheet shows).
  final int? etaSeconds, etaToHospitalSeconds;
  final String? verificationCode;
  final int? bagCount;
  final String bloodSummary;

  const DeliveryTracking({
    required this.id,
    required this.identifier,
    required this.bloodRequestId,
    required this.phase,
    required this.assignmentStatus,
    this.pickupConfirmedAt,
    required this.bloodBank,
    required this.hospital,
    this.courierName,
    this.courierPhone,
    this.courierPosition,
    this.courierLastSeenAt,
    this.routeLegs = const {},
    this.activeLeg,
    this.etaSeconds,
    this.etaToHospitalSeconds,
    this.verificationCode,
    this.bagCount,
    this.bloodSummary = '',
  });

  factory DeliveryTracking.fromJson(Map<String, dynamic> json) {
    final person = _map(json['delivery_person']);
    final pos = _map(json['courier_position']);
    final lat = _num(pos['lat']), lng = _num(pos['lng']);
    final legs = <String, TrackingLeg>{};
    _map(json['route_legs']).forEach((k, v) {
      if (v is Map) legs[k] = TrackingLeg.fromJson(Map<String, dynamic>.from(v));
    });

    return DeliveryTracking(
      id: _str(json['id']) ?? '',
      identifier: _str(json['identifier']) ?? '',
      bloodRequestId: _str(json['blood_request_id']) ?? '',
      phase: _str(json['delivery_phase']) ?? '',
      assignmentStatus: _str(json['assignment_status']) ?? '',
      pickupConfirmedAt: _time(json['pickup_confirmed_by_seller_at']),
      bloodBank: TrackingPlace.fromJson(json['blood_bank']),
      hospital: TrackingPlace.fromJson(json['hospital']),
      courierName: _str(person['name']),
      courierPhone: _str(person['phone']),
      courierPosition: lat != null && lng != null ? (lat: lat.toDouble(), lng: lng.toDouble()) : null,
      courierLastSeenAt: _time(json['courier_last_seen_at']),
      routeLegs: legs,
      activeLeg: _str(json['active_leg']),
      etaSeconds: _num(json['eta_s'])?.round(),
      etaToHospitalSeconds: _num(json['eta_to_hospital_s'])?.round(),
      verificationCode: _str(json['delivery_verification_code']),
      bagCount: _num(json['bag_count'])?.round(),
      bloodSummary: _str(json['blood_summary']) ?? '',
    );
  }

  bool get isCancelled => phase == 'cancelled';
  bool get isDelivered => phase == 'delivered_and_confirmed';

  TrackingLeg? get currentLeg => activeLeg == null ? null : routeLegs[activeLeg];

  Duration? positionAge(DateTime nowUtc) =>
      courierLastSeenAt == null ? null : nowUtc.difference(courierLastSeenAt!);

  bool isStale(DateTime nowUtc) {
    final age = positionAge(nowUtc);
    return age != null && age > staleAfter;
  }
}

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

String? _str(Object? v) => v?.toString();

num? _num(Object? v) => v is num ? v : (v is String ? num.tryParse(v) : null);

DateTime? _time(Object? v) {
  if (v == null) return null;
  try {
    return parseServerTime(v.toString());
  } on FormatException {
    return null;
  }
}
