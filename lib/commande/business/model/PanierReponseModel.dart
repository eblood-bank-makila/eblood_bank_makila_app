// To parse this JSON data, do
//
//     final panierReponseModel = panierReponseModelFromJson(jsonString);

import 'dart:convert';

PanierReponseModel panierReponseModelFromJson(String str) =>
    PanierReponseModel.fromJson(json.decode(str));

String panierReponseModelToJson(PanierReponseModel data) =>
    json.encode(data.toJson());

class PanierReponseModel {
  String sms;
  int statusCode;
  bool success;

  PanierReponseModel({
    required this.sms,
    required this.statusCode,
    required this.success,
  });

  factory PanierReponseModel.fromJson(Map<String, dynamic> json) =>
      PanierReponseModel(
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
