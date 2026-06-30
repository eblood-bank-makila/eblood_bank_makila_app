import 'dart:convert';

PaiementModel paiementModelFromJson(String str) =>
    PaiementModel.fromJson(json.decode(str));

String paiementModelToJson(PaiementModel data) =>
    json.encode(data.toJson());

class PaiementModel {
  final String cartId;
  final String? phoneNumber;
  final String? transactionalCurrencyId;
  // Blood request context
  final String? requestFor; // 'patient' | 'storage'
  final String? requestReason;
  final String? patientId;
  final String? requestType; // e.g., TRAUMA, ANEMIA_SEVERE, ...
  final String? urgencyLevel; // e.g., ROUTINE, PRIORITY, URGENT, CRITICAL, EMERGENCY

  PaiementModel({
    required this.cartId,
    this.phoneNumber,
    this.transactionalCurrencyId,
    this.requestFor,
    this.requestReason,
    this.patientId,
    this.requestType,
    this.urgencyLevel,
  });

  factory PaiementModel.fromJson(Map json) => PaiementModel(
    cartId: json['cart_id'],
    phoneNumber: json['phone_number'],
    transactionalCurrencyId: json['transactional_currency_id'],
    requestFor: json['request_for'],
    requestReason: json['request_reason'],
    patientId: json['patient_id'],
    requestType: json['request_type'],
    urgencyLevel: json['urgency_level'],
  );

  Map<String, dynamic> toJson() => {
    'cart_id': cartId,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (transactionalCurrencyId != null) 'transactional_currency_id': transactionalCurrencyId,
    if (requestFor != null) 'request_for': requestFor,
    if (requestReason != null) 'request_reason': requestReason,
    if (patientId != null) 'patient_id': patientId,
    if (requestType != null) 'request_type': requestType,
    if (urgencyLevel != null) 'urgency_level': urgencyLevel,
  };
}
