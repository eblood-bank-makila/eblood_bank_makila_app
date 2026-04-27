/// Sprint M — typed FCM payload for the dead-hand auto-broadcast.
///
/// The backend sends:
/// - `data['type']`        == `'dead_hand_broadcast'`
/// - `data['order_id']`    == ObjectId string
/// - `data['round']`       == `'1'` | `'2'` | `'3'`
/// - `data['radius_km']`   == `'5.0'` | `'15.0'` | `'global'`
/// - `data['ttl_seconds']` == `'60'`
///
/// Everything is a string because FCM's `data` map only carries strings.
/// This payload class parses + validates them into typed values.
class DeadHandAlertPayload {
  static const String typeName = 'dead_hand_broadcast';

  final String orderId;
  final int round;
  final double? radiusKm; // null when broadcast is global
  final int ttlSeconds;

  const DeadHandAlertPayload({
    required this.orderId,
    required this.round,
    required this.radiusKm,
    required this.ttlSeconds,
  });

  /// Parse an FCM `data` map. Returns `null` if the type isn't ours
  /// or the payload is malformed — callers should treat null as
  /// "skip this message, let the default handler take it".
  static DeadHandAlertPayload? tryParse(Map<String, dynamic> data) {
    if (data['type']?.toString() != typeName) return null;

    final orderId = data['order_id']?.toString() ?? '';
    if (orderId.isEmpty) return null;

    final round = int.tryParse(data['round']?.toString() ?? '') ?? 1;

    final radiusRaw = data['radius_km']?.toString() ?? '';
    final double? radiusKm =
        radiusRaw.isEmpty || radiusRaw == 'global' ? null : double.tryParse(radiusRaw);

    final ttl = int.tryParse(data['ttl_seconds']?.toString() ?? '') ?? 60;

    return DeadHandAlertPayload(
      orderId: orderId,
      round: round,
      radiusKm: radiusKm,
      ttlSeconds: ttl,
    );
  }

  /// Human-friendly subtitle for the dialog ("Round 2 — 15 km").
  String get scopeLabel {
    final radius = radiusKm == null ? 'tout le réseau' : '${radiusKm!.toStringAsFixed(0)} km';
    return 'Round $round — $radius';
  }
}
