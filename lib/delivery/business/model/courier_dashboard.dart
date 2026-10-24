import 'DeliveryModels.dart' show parseServerTime;

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
  });

  final String id, phase;
  final String? hospitalName, bloodBankName, priority;
  final DateTime? acceptedAt, confirmedAt, updatedAt;

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
    );
  }

  bool get isUrgent => const {'high', 'critical', 'emergency'}.contains(priority);
}
