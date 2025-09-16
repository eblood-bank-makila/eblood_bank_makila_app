
// To parse this JSON data, do
//
//     final paiementResponseModel = paiementResponseModelFromJson(jsonString);

import 'dart:convert';

DatumPaiementModel datumPaiementModelFromJson(String str) => DatumPaiementModel.fromJson(json.decode(str));

String datumPaiementModelToJson(DatumPaiementModel data) => json.encode(data.toJson());

class DatumPaiementModel {
  String systemRef;

  DatumPaiementModel ({
   required this.systemRef,
  });

  factory DatumPaiementModel.fromJson(Map<String, dynamic> json) => DatumPaiementModel (
    systemRef: json["systemRef"],
  );

  Map<String, dynamic> toJson() => {
    "systemRef": systemRef,
  };
}