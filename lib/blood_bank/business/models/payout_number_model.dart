/// Validation lifecycle of one cash-out (payout) number registered by the
/// org (blood bank / CNTS) and validated by the MAIN profile.
enum PayoutNumberStatus { pendingValidation, validated, rejected, disabled }

PayoutNumberStatus payoutStatusFrom(String? raw) {
  switch ((raw ?? '').toLowerCase()) {
    case 'validated':
      return PayoutNumberStatus.validated;
    case 'rejected':
      return PayoutNumberStatus.rejected;
    case 'disabled':
      return PayoutNumberStatus.disabled;
    default:
      return PayoutNumberStatus.pendingValidation;
  }
}

/// A payout (cash-out) phone number registered by an org for settlement
/// withdrawals. Must be `validated` by the MAIN profile before it can be
/// used to submit a withdrawal.
class PayoutNumberModel {
  final String id;
  final String sysOrganizationId;
  final String phoneNumber;
  final String holderName;
  final String? operatorHint;
  final double maxAmountPerDay;
  final int priority;
  final PayoutNumberStatus validationStatus;
  final String? rejectionReason;
  final String? validatedAt;
  final String? createdAt;

  const PayoutNumberModel({
    required this.id,
    required this.sysOrganizationId,
    required this.phoneNumber,
    required this.holderName,
    this.operatorHint,
    required this.maxAmountPerDay,
    required this.priority,
    required this.validationStatus,
    this.rejectionReason,
    this.validatedAt,
    this.createdAt,
  });

  bool get isValidated => validationStatus == PayoutNumberStatus.validated;

  factory PayoutNumberModel.fromJson(Map<String, dynamic> j) => PayoutNumberModel(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        sysOrganizationId: (j['sys_organization_id'] ?? '').toString(),
        phoneNumber: (j['phone_number'] ?? '').toString(),
        holderName: (j['holder_name'] ?? '').toString(),
        operatorHint: j['operator_hint']?.toString(),
        maxAmountPerDay: (j['max_amount_per_day'] is num)
            ? (j['max_amount_per_day'] as num).toDouble()
            : double.tryParse('${j['max_amount_per_day']}') ?? 0,
        priority: (j['priority'] is num) ? (j['priority'] as num).toInt() : int.tryParse('${j['priority']}') ?? 1,
        validationStatus: payoutStatusFrom(j['validation_status']?.toString()),
        rejectionReason: j['rejection_reason']?.toString(),
        validatedAt: j['validated_at']?.toString(),
        createdAt: j['created_at']?.toString(),
      );

  Map<String, dynamic> toPayload() => {
        'phone_number': phoneNumber,
        'holder_name': holderName,
        'operator_hint': operatorHint,
        'max_amount_per_day': maxAmountPerDay,
        'priority': priority,
      };
}
