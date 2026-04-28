
// To parse this JSON data, do
//
//     final paiementResponseModel = paiementResponseModelFromJson(jsonString);

import 'dart:convert';

DatumPaiementModel datumPaiementModelFromJson(String str) => DatumPaiementModel.fromJson(json.decode(str));

String datumPaiementModelToJson(DatumPaiementModel data) => json.encode(data.toJson());

class DatumPaiementModel {
  /// Sprint 15 — `systemRef` now carries the backend's
  /// `customer_reference` (an opaque, gateway-agnostic id). The field
  /// name is kept for backward-compat with all the navigation /
  /// status-page plumbing already wired up around it.
  String systemRef;
  String? bloodRequestId;

  DatumPaiementModel ({
   required this.systemRef,
   this.bloodRequestId,
  });

  factory DatumPaiementModel.fromJson(Map<String, dynamic> json) => DatumPaiementModel (
    // Sprint 15 — accept the new `customer_reference` field first;
    // fall back to legacy aliases so any cached responses still parse.
    systemRef: json["customer_reference"]
        ?? json["systemRef"]
        ?? json["blood_request_identifier"]
        ?? '',
    bloodRequestId: json["blood_request_id"] ?? json["entity_id"],
  );

  Map<String, dynamic> toJson() => {
    "systemRef": systemRef,
    "blood_request_id": bloodRequestId,
  };
}