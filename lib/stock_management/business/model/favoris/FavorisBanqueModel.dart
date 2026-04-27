// To parse this JSON data, do
//
//     final favorisBanqueModel = favorisBanqueModelFromJson(jsonString);

import 'dart:convert';

FavorisBanqueModel favorisBanqueModelFromJson(String str) => FavorisBanqueModel.fromJson(json.decode(str));

String favorisBanqueModelToJson(FavorisBanqueModel data) => json.encode(data.toJson());

class FavorisBanqueModel {
  String sms;
  int statusCode;
  bool success;
  String blood_bank_id;

  FavorisBanqueModel({
    required this.sms,
    required this.statusCode,
    this.success = false,
   required this.blood_bank_id,
  });

  factory FavorisBanqueModel.fromJson(Map<String, dynamic> json) => FavorisBanqueModel(
    sms: json["sms"],
    statusCode: json["status_code"],
    success: json["success"],
    blood_bank_id: json["blood_bank_id"],
  );

  Map<String, dynamic> toJson() => {
    "sms": sms,
    "status_code": statusCode,
    "success": success,
    "blood_bank_id": blood_bank_id,
  };
}
