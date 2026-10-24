import 'DeliveryModels.dart' show Delivery, DeliveryPriority, DeliveryStatus, parseServerTime;

/// GET /eblood-connect/delivery-assignment/my-dashboard: the token's courier's
/// counters and most recent deliveries.
class CourierDashboard {
  const CourierDashboard({
    this.total = 0,
    this.inProgress = 0,
    this.delivered = 0,
    this.urgent = 0,
    this.deliveries = const [],
  });

  final int total, inProgress, delivered, urgent;
  final List<CourierDeliveryRow> deliveries;

  factory CourierDashboard.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] is Map ? Map<String, dynamic>.from(json['stats']) : const <String, dynamic>{};
    int n(String k) => (stats[k] as num?)?.toInt() ?? 0;
    return CourierDashboard(
      total: n('total'),
      inProgress: n('in_progress'),
      delivered: n('delivered'),
      urgent: n('urgent'),
      deliveries: (json['deliveries'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => CourierDeliveryRow.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }

  /// Deliveries with something today (accepted, confirmed or updated), local
  /// time: one accepted days ago and delivered today belongs to today.
  List<CourierDeliveryRow> get today {
    final now = DateTime.now();
    bool isToday(DateTime? t) {
      final l = t?.toLocal();
      return l != null && l.year == now.year && l.month == now.month && l.day == now.day;
    }

    return deliveries.where((d) => isToday(d.acceptedAt) || isToday(d.confirmedAt) || isToday(d.updatedAt)).toList();
  }
}

class CourierDeliveryRow {
  const CourierDeliveryRow({
    required this.id,
    required this.phase,
    this.hospitalName,
    this.bloodBankName,
    this.priority,
    this.acceptedAt,
    this.confirmedAt,
    this.updatedAt,
    this.bagCount = 0,
    this.bloodSummary = '',
  });

  final String id, phase;
  final String? hospitalName, bloodBankName, priority;
  final DateTime? acceptedAt, confirmedAt, updatedAt;
  final int bagCount;
  final String bloodSummary; // « 1 × AB-, 2 × O+ »

  factory CourierDeliveryRow.fromJson(Map<String, dynamic> json) {
    DateTime? t(String k) => json[k] == null ? null : parseServerTime(json[k].toString());
    return CourierDeliveryRow(
      id: json['id']?.toString() ?? '',
      phase: json['delivery_phase']?.toString() ?? '',
      hospitalName: json['hospital_name']?.toString(),
      bloodBankName: json['blood_bank_name']?.toString(),
      priority: json['priority']?.toString(),
      acceptedAt: t('accepted_at'),
      confirmedAt: t('confirmed_at'),
      updatedAt: t('updated_at'),
      bagCount: (json['bag_count'] as num?)?.toInt() ?? 0,
      bloodSummary: json['blood_summary']?.toString() ?? '',
    );
  }

  /// The « Mes livraisons » page's [Delivery], built from this row.
  Delivery toDelivery() {
    final now = DateTime.now();
    final firstType = bloodSummary.split(',').first.split('×').last.trim();
    return Delivery(
      id: id,
      requestId: '',
      hospitalName: hospitalName ?? '—',
      hospitalAddress: bloodBankName ?? '', // the page's second line: where the bags come from
      bloodType: firstType.isEmpty ? '?' : firstType,
      quantity: bagCount,
      status: switch (phase) {
        'delivered_and_confirmed' => DeliveryStatus.delivered,
        'cancelled' => DeliveryStatus.cancelled,
        'en_route_to_blood_bank' || 'at_blood_bank' => DeliveryStatus.assigned,
        'picked_up_from_blood_bank' || 'en_route_to_hospital' || 'at_hospital' => DeliveryStatus.inProgress,
        _ => DeliveryStatus.pending,
      },
      priority: switch (priority) {
        'emergency' || 'critical' => DeliveryPriority.emergency,
        'high' => DeliveryPriority.urgent,
        _ => DeliveryPriority.normal,
      },
      deliveryPersonId: '',
      deliveryPersonName: '',
      requestDate: acceptedAt ?? updatedAt ?? now,
      assignedDate: acceptedAt,
      deliveredDate: confirmedAt,
      createdAt: acceptedAt ?? updatedAt ?? now,
      updatedAt: updatedAt ?? now,
    );
  }

  bool get isUrgent => const {'high', 'critical', 'emergency'}.contains(priority);
}
