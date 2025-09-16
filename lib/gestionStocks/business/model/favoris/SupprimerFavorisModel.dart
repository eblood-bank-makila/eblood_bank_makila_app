// To parse this JSON data, do
//
//     final supprimerFavorisModel = supprimerFavorisModelFromJson(jsonString);

import 'dart:convert';

SupprimerFavorisModel supprimerFavorisModelFromJson(String str) =>
    SupprimerFavorisModel.fromJson(json.decode(str));

String supprimerFavorisModelToJson(SupprimerFavorisModel data) =>
    json.encode(data.toJson());

class SupprimerFavorisModel {
  String sms;
  int statusCode;
  bool success;

  SupprimerFavorisModel({
    required this.sms,
    required this.statusCode,
    required this.success,
  });

  factory SupprimerFavorisModel.fromJson(Map<String, dynamic> json) =>
      SupprimerFavorisModel(
        sms: json["sms"],
        statusCode: json["status_code"],
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "sms": sms,
        "status_code": statusCode,
        "success": success,
      };
}
