/// Data of the courier call pushes sent by the backend dispatch
/// (courier_dispatch_service): `delivery_call` rings, `delivery_call_closed`
/// silences (reason taken | expired | cancelled). All values arrive as strings.
/// The live-tracking pushes (`delivery_assigned`, `delivery_closed`,
/// `delivery_progress`) are parsed at the end of this file.
library;

class DeliveryCallPayload {
  static const callType = 'delivery_call';
  static const closedType = 'delivery_call_closed';

  final String deliveryId;
  final String identifier;
  final DateTime callEndsAt;
  final String bloodBankName;
  final String bloodBankAddress;
  final String hospitalName;
  final String hospitalAddress;
  final double? kmToBloodBank;
  final double? kmBankToHospital;
  final int? bagCount;
  final String bloodSummary;
  final String priority;

  const DeliveryCallPayload({
    required this.deliveryId,
    required this.identifier,
    required this.callEndsAt,
    required this.bloodBankName,
    required this.bloodBankAddress,
    required this.hospitalName,
    required this.hospitalAddress,
    required this.kmToBloodBank,
    required this.kmBankToHospital,
    required this.bagCount,
    required this.bloodSummary,
    required this.priority,
  });

  bool get isUrgent => const {'high', 'critical', 'emergency', 'urgent'}.contains(priority);

  Duration timeLeft([DateTime? now]) {
    final left = callEndsAt.difference(now ?? DateTime.now().toUtc());
    return left.isNegative ? Duration.zero : left;
  }

  /// Null unless `data` is a well-formed `delivery_call`.
  static DeliveryCallPayload? tryParse(Map<String, dynamic> data) {
    if (data['type']?.toString() != callType) return null;
    final id = data['delivery_id']?.toString() ?? '';
    final ends = DateTime.tryParse(data['call_ends_at']?.toString() ?? '');
    if (id.isEmpty || ends == null) return null;
    String s(String k) => data[k]?.toString() ?? '';
    return DeliveryCallPayload(
      deliveryId: id,
      identifier: s('identifier'),
      callEndsAt: ends.toUtc(),
      bloodBankName: s('blood_bank_name'),
      bloodBankAddress: s('blood_bank_address'),
      hospitalName: s('hospital_name'),
      hospitalAddress: s('hospital_address'),
      kmToBloodBank: double.tryParse(s('km_to_blood_bank')),
      kmBankToHospital: double.tryParse(s('km_bank_to_hospital')),
      bagCount: int.tryParse(s('bag_count')),
      bloodSummary: s('blood_summary'),
      priority: s('priority').isEmpty ? 'normal' : s('priority'),
    );
  }
}

/// `delivery_call_closed`: which call stopped and why.
class DeliveryCallClosed {
  final String deliveryId;
  final String reason; // taken | expired | cancelled

  const DeliveryCallClosed(this.deliveryId, this.reason);

  static DeliveryCallClosed? tryParse(Map<String, dynamic> data) {
    if (data['type']?.toString() != DeliveryCallPayload.closedType) return null;
    final id = data['delivery_id']?.toString() ?? '';
    return id.isEmpty ? null : DeliveryCallClosed(id, data['reason']?.toString() ?? 'expired');
  }

  String get message => reason == 'taken' || reason == 'cancelled'
      ? 'Course prise par un autre livreur.'
      : 'Appel terminé.';
}

String _id(Map<String, dynamic> data) => data['delivery_id']?.toString() ?? '';

/// `delivery_assigned`: the console gave this courier a delivery.
class DeliveryAssigned {
  static const type = 'delivery_assigned';

  final String deliveryId;

  const DeliveryAssigned(this.deliveryId);

  static DeliveryAssigned? tryParse(Map<String, dynamic> data) {
    if (data['type']?.toString() != type) return null;
    final id = _id(data);
    return id.isEmpty ? null : DeliveryAssigned(id);
  }
}

/// `delivery_closed` (data only): the courier no longer has this delivery.
class DeliveryClosed {
  static const type = 'delivery_closed';

  final String deliveryId;
  final String reason; // unassigned | cancelled

  const DeliveryClosed(this.deliveryId, this.reason);

  static DeliveryClosed? tryParse(Map<String, dynamic> data) {
    if (data['type']?.toString() != type) return null;
    final id = _id(data);
    return id.isEmpty ? null : DeliveryClosed(id, data['reason']?.toString() ?? 'unassigned');
  }

  /// Translation key of what the courier is told.
  String get messageKey => reason == 'cancelled' ? 'delivery_cancelled_by_admin' : 'delivery_reassigned';
}

/// `delivery_progress`: a delivery the structure follows moved on (event
/// picked_up, at_blood_bank, ...). [audience] says which side it was sent to.
class DeliveryProgress {
  static const type = 'delivery_progress';

  final String deliveryId;
  final String phase;
  final String event;
  final String audience; // buyer | seller

  const DeliveryProgress(this.deliveryId, this.phase, this.event, this.audience);

  static DeliveryProgress? tryParse(Map<String, dynamic> data) {
    if (data['type']?.toString() != type) return null;
    final id = _id(data);
    if (id.isEmpty) return null;
    String s(String k) => data[k]?.toString() ?? '';
    return DeliveryProgress(id, s('phase'), s('event'), s('audience'));
  }

  bool get isSeller => audience == 'seller';
}
