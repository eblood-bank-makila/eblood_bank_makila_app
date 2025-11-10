import 'package:freezed_annotation/freezed_annotation.dart';

part 'blood_request_model.freezed.dart';
part 'blood_request_model.g.dart';

// Helper converters to handle multiple backend shapes safely
String? _stringFromJson(dynamic v) => v is String ? v : null;
dynamic _readId(Map json, String key) => json['_id'] ?? json['id'];
String? _readHealthStructureRequestingId(Map json, String key) {
  final v = json['health_structure_requesting_id'];
  if (v is String) return v;
  final obj = json['health_structure_requesting'];
  if (obj is Map && obj['id'] is String) return obj['id'] as String;
  return null;
}
String? _readRefCurrencyId(Map json, String key) {
  final v = json['ref_currency_id'];
  if (v is String) return v;
  final obj = json['ref_currency'];
  if (obj is Map && obj['id'] is String) return obj['id'] as String;
  return null;
}
String? _readTransactionalCurrencyId(Map json, String key) {
  final v = json['transactional_currency_id'];
  if (v is String) return v;
  final obj = json['transactional_currency'];
  if (obj is Map && obj['id'] is String) return obj['id'] as String;
  return null;
}

// Cache to hold requested blood bags per request id (populated via fromApiJson)
final Map<String, List<RequestedBloodBag>> _opsBagsCache = {};

/// Blood request model matching backend OpsBloodRequestModel
@freezed
class BloodRequestModel with _$BloodRequestModel {
  const factory BloodRequestModel({
    @JsonKey(name: '_id', readValue: _readId) required String id,
    required String identifier,
    @JsonKey(name: 'health_structure_requesting_id', readValue: _readHealthStructureRequestingId) String? healthStructureRequestingId,
    @JsonKey(name: 'sys_organization_id', fromJson: _stringFromJson) String? sysOrganizationId,
    @JsonKey(name: 'request_type') required String requestType,
    @JsonKey(name: 'urgency_level') required String urgencyLevel,
    @JsonKey(name: 'patient_blood_group') required String patientBloodGroup,
    @JsonKey(name: 'patient_rh_factor') required String patientRhFactor,
    @JsonKey(name: 'requested_components') @Default([]) List<BloodRequestComponent> requestedComponents,

    @JsonKey(name: 'requested_delivery_time') String? requestedDeliveryTime,
    @JsonKey(name: 'clinical_indication') String? clinicalIndication,
    @JsonKey(name: 'requested_by') String? requestedBy,
    @JsonKey(name: 'delivery_contact') DeliveryContact? deliveryContact,
    required String status,
    @JsonKey(name: 'status_history') List<StatusHistory>? statusHistory,
    String? notes,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
    @JsonKey(name: 'soft_deleted') @Default(false) bool softDeleted,
    @JsonKey(name: 'onafriq_transaction_ref') String? onafriqTransactionRef,
    @JsonKey(name: 'failure_reason') String? failureReason,
    @JsonKey(name: 'phone_number') String? phoneNumber,
    @JsonKey(name: 'eblood_fee') double? ebloodFee,
    @JsonKey(name: 'ref_currency_id', readValue: _readRefCurrencyId) String? refCurrencyId,
    @JsonKey(name: 'transactional_eblood_fee') double? transactionalEbloodFee,
    @JsonKey(name: 'transactional_currency_id', readValue: _readTransactionalCurrencyId) String? transactionalCurrencyId,
  }) = _BloodRequestModel;

  factory BloodRequestModel.fromJson(Map<String, dynamic> json) =>
      _$BloodRequestModelFromJson(json);

  /// Custom parser to accept multiple backend shapes from list endpoints
  static BloodRequestModel fromApiJson(Map<String, dynamic> json) {
    final idVal = (json['_id'] ?? json['id']) as String? ?? '';

    final pm = json['payment_metadata'];
    final cartIdentifier = pm is Map<String, dynamic> ? pm['cart_identifier'] as String? : null;
    final identifierVal = (json['identifier'] as String?) ?? cartIdentifier ?? idVal;

    String? healthStructureRequestingId;
    DeliveryContact? deliveryContact;
    final hs = json['health_structure_requesting'];
    if (hs is Map<String, dynamic>) {
      healthStructureRequestingId = hs['id'] as String?;
      final name = (hs['name'] as String?)?.trim();
      final phone = (hs['phone_number'] as String?) ?? (json['phone_number'] as String?) ?? '—';
      final email = hs['email'] as String?;
      final address = hs['address'] as String?;
      if (name != null && name.isNotEmpty) {
        deliveryContact = DeliveryContact(
          name: name,
          phone: phone,
          email: email,
          address: address,
        );
      }
    }

    final sysOrgRaw = json['sys_organization_id'];
    final sysOrgId = sysOrgRaw is String ? sysOrgRaw : null;

    final refCurrencyObj = json['ref_currency'];
    final refCurrencyId = (json['ref_currency_id'] as String?) ??
        (refCurrencyObj is Map<String, dynamic> ? refCurrencyObj['id'] as String? : null);

    final tranCurrencyObj = json['transactional_currency'];
    final transactionalCurrencyId = (json['transactional_currency_id'] as String?) ??
        (tranCurrencyObj is Map<String, dynamic> ? tranCurrencyObj['id'] as String? : null);

    final createdAt = (json['created_at'] as String?) ??
        (json['onafriq_init_response'] is Map<String, dynamic>
            ? (json['onafriq_init_response']['created'] as String?)
            : null) ??
        DateTime.now().toIso8601String();

    final updatedAt = (json['updated_at'] as String?) ??
        (json['onafriq_init_response'] is Map<String, dynamic>
            ? ((json['onafriq_init_response']['modified'] ?? json['onafriq_init_response']['created']) as String?)
            : null) ??
        createdAt;

    // Parse ops_blood_bags_requested (if any)
    final opsListRaw = json['ops_blood_bags_requested'];
    final opsBags = (opsListRaw is List)
        ? opsListRaw.whereType<Map<String, dynamic>>().map(RequestedBloodBag.fromApiJson).toList()
        : <RequestedBloodBag>[];

    final model = BloodRequestModel(
      id: idVal,
      identifier: identifierVal,
      healthStructureRequestingId: healthStructureRequestingId,
      sysOrganizationId: sysOrgId,
      requestType: json['request_type'] as String? ?? 'unknown',
      urgencyLevel: json['urgency_level'] as String? ?? 'normal',
      patientBloodGroup: json['patient_blood_group'] as String? ?? '?',
      patientRhFactor: json['patient_rh_factor'] as String? ?? '',
      requestedComponents: const [],
      requestedDeliveryTime: json['requested_delivery_time'] as String?,
      clinicalIndication: json['clinical_indication'] as String?,
      requestedBy: json['requested_by'] as String?,
      deliveryContact: deliveryContact,
      status: json['status'] as String? ?? 'requested',
      statusHistory: null,
      notes: json['notes'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      softDeleted: json['soft_deleted'] as bool? ?? false,
      onafriqTransactionRef: json['onafriq_transaction_ref'] as String?,
      failureReason: json['failure_reason'] as String?,
      phoneNumber: json['phone_number'] as String?,
      ebloodFee: (json['eblood_fee'] as num?)?.toDouble(),
      refCurrencyId: refCurrencyId,
      transactionalEbloodFee: (json['transactional_eblood_fee'] as num?)?.toDouble(),
      transactionalCurrencyId: transactionalCurrencyId,
    );

    // Store parsed ops blood bags in cache for this request id
    _opsBagsCache[idVal] = opsBags;

    return model;
  }
}

@freezed
class BloodRequestComponent with _$BloodRequestComponent {
  const factory BloodRequestComponent({
    @JsonKey(name: 'blood_product_type') required String bloodProductType,
    required int quantity,
    String? volume,
    @JsonKey(name: 'blood_bag_id') String? bloodBagId,
    @JsonKey(name: 'blood_bank_id') String? bloodBankId,
  }) = _BloodRequestComponent;

  factory BloodRequestComponent.fromJson(Map<String, dynamic> json) =>
      _$BloodRequestComponentFromJson(json);
}

@freezed
class DeliveryContact with _$DeliveryContact {
  const factory DeliveryContact({
    required String name,
    required String phone,
    String? email,
    String? address,
  }) = _DeliveryContact;

  factory DeliveryContact.fromJson(Map<String, dynamic> json) =>
      _$DeliveryContactFromJson(json);
}

@freezed
class StatusHistory with _$StatusHistory {
  const factory StatusHistory({
    required String status,
    required String timestamp,
    @JsonKey(name: 'changed_by') String? changedBy,
    String? notes,
  }) = _StatusHistory;

  factory StatusHistory.fromJson(Map<String, dynamic> json) =>
      _$StatusHistoryFromJson(json);
}

/// Minimal view model for requested blood bags attached to a request
class RequestedBloodBag {
  final String id;
  final String identifier;
  final double? amount;
  final String status;
  final String? statusLabel;
  final String? statusTextColorHex;
  final String? statusBgColorHex;
  final String? currencySymbol;
  final String? currencyCode;
  final String? rhesusFactor;
  final String? volume;

  const RequestedBloodBag({
    required this.id,
    required this.identifier,
    required this.status,
    this.amount,
    this.statusLabel,
    this.statusTextColorHex,
    this.statusBgColorHex,
    this.currencySymbol,
    this.currencyCode,
    this.rhesusFactor,
    this.volume,
  });

  factory RequestedBloodBag.fromApiJson(Map<String, dynamic> json) {
    final statusColor = json['status_color'];
    final refCurrency = json['ref_currency'];
    final stockBag = json['stock_blood_bag'];
    return RequestedBloodBag(
      id: (json['id'] ?? json['_id'] ?? '') as String,
      identifier: (json['identifier'] as String?) ?? '',
      amount: (json['amount'] as num?)?.toDouble(),
      status: (json['status'] as String?) ?? 'requested',
      statusLabel: json['status_lbl'] as String?,
      statusTextColorHex: statusColor is Map<String, dynamic> ? statusColor['textColor'] as String? : null,
      statusBgColorHex: statusColor is Map<String, dynamic> ? statusColor['backgroundColor'] as String? : null,
      currencySymbol: refCurrency is Map<String, dynamic> ? refCurrency['symbol'] as String? : null,
      currencyCode: refCurrency is Map<String, dynamic> ? refCurrency['code'] as String? : null,
      rhesusFactor: stockBag is Map<String, dynamic> ? stockBag['rhesus_factor'] as String? : null,
      volume: stockBag is Map<String, dynamic> ? stockBag['volume'] as String? : null,
    );
  }
}


/// Response model for blood requests list
@freezed
class BloodRequestsResponse with _$BloodRequestsResponse {
  const factory BloodRequestsResponse({
    required List<BloodRequestModel> data,
    required int total,
    required int page,
    required int limit,
  }) = _BloodRequestsResponse;

  factory BloodRequestsResponse.fromJson(Map<String, dynamic> json) =>
      _$BloodRequestsResponseFromJson(json);
}

/// Extension methods for BloodRequestModel
extension BloodRequestModelX on BloodRequestModel {
  /// Get patient blood type display (e.g., "O+", "A-")
  String get patientBloodTypeDisplay {
    return '$patientBloodGroup$patientRhFactor';
  }


  /// Requested blood bags parsed from API (via cache)
  List<RequestedBloodBag> get opsBloodBagsRequested => _opsBagsCache[id] ?? const [];

  /// Check if request is urgent
  bool get isUrgent => urgencyLevel == 'urgent' || urgencyLevel == 'critical' || urgencyLevel == 'emergency';

  /// Get total units requested from requestedComponents
  int get totalUnitsRequested => requestedComponents.fold(0, (sum, component) => sum + component.quantity);

  /// Effective units requested (fallback to opsBloodBagsRequested length)
  int get effectiveUnitsRequested =>
      totalUnitsRequested > 0 ? totalUnitsRequested : opsBloodBagsRequested.length;

  /// Get formatted delivery time
  DateTime? get deliveryDateTime {
    try {
      return requestedDeliveryTime != null ? DateTime.parse(requestedDeliveryTime!) : null;
    } catch (e) {
      return null;
    }
  }

  /// Get formatted created time
  DateTime? get createdDateTime {
    try {
      return DateTime.parse(createdAt);
    } catch (e) {
      return null;
    }
  }

  /// Check if payment is completed
  bool get isPaymentCompleted => status == 'completed' || status == 'approved';

  /// Check if payment failed
  bool get isPaymentFailed => status == 'failed' || status == 'cancelled' || status == 'declined' || status == 'rejected' || status == 'expired' || status == 'timeout';

  /// Check if payment is pending
  bool get isPaymentPending => status == 'pending' || status == 'requested' || status == 'processing';
}

