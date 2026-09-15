/// One cash-out (withdrawal) record against a payout number, including
/// auto-checkout sweeps triggered by the escrow release.
class CashOutModel {
  final String id;
  final String status;
  final String phoneNumber;
  final double amount;
  final String? providerRef;
  final String? failureReason;
  final String? opsEwalletId;
  final String? createdAt;
  final String? withdrawedAt;
  final bool isAutoCheckout;

  const CashOutModel({
    required this.id,
    required this.status,
    required this.phoneNumber,
    required this.amount,
    this.providerRef,
    this.failureReason,
    this.opsEwalletId,
    this.createdAt,
    this.withdrawedAt,
    required this.isAutoCheckout,
  });

  factory CashOutModel.fromJson(Map<String, dynamic> j) => CashOutModel(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        status: (j['status'] ?? '').toString(),
        phoneNumber: (j['phone_number'] ?? '').toString(),
        amount: (j['amount'] is num) ? (j['amount'] as num).toDouble() : double.tryParse('${j['amount']}') ?? 0,
        providerRef: j['provider_ref']?.toString(),
        failureReason: j['failure_reason']?.toString(),
        opsEwalletId: j['ops_ewallet_id']?.toString(),
        createdAt: j['created_at']?.toString(),
        withdrawedAt: j['withdrawed_at']?.toString(),
        isAutoCheckout: j['is_auto_checkout'] == true,
      );
}
