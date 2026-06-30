
// To parse this JSON data, do
//
//     final paiementResponseModel = paiementResponseModelFromJson(jsonString);

import 'dart:convert';

DatumPaiementModel datumPaiementModelFromJson(String str) => DatumPaiementModel.fromJson(json.decode(str));

String datumPaiementModelToJson(DatumPaiementModel data) => json.encode(data.toJson());

class DatumPaiementModel {
  String systemRef;
  String? bloodRequestId;
  String? onafriqTransactionRef;
  String? onafriqState;

  DatumPaiementModel ({
   required this.systemRef,
   this.bloodRequestId,
   this.onafriqTransactionRef,
   this.onafriqState,
  });

  factory DatumPaiementModel.fromJson(Map<String, dynamic> json) => DatumPaiementModel (
    // Support both old (systemRef) and new (blood_request_identifier) field names
    systemRef: json["systemRef"] ?? json["blood_request_identifier"] ?? '',
    bloodRequestId: json["blood_request_id"],
    onafriqTransactionRef: json["onafriq_transaction_ref"],
    onafriqState: json["onafriq_state"],
  );

  Map<String, dynamic> toJson() => {
    "systemRef": systemRef,
    "blood_request_id": bloodRequestId,
    "onafriq_transaction_ref": onafriqTransactionRef,
    "onafriq_state": onafriqState,
  };
}