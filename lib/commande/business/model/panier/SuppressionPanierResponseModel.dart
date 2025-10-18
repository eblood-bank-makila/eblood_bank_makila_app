// To parse this JSON data, do
//
//     final suppressionPanierResponseModel = suppressionPanierResponseModelFromJson(jsonString);

import 'dart:convert';

SuppressionPanierResponseModel suppressionPanierResponseModelFromJson(
        String str) =>
    SuppressionPanierResponseModel.fromJson(json.decode(str));

String suppressionPanierResponseModelToJson(
        SuppressionPanierResponseModel data) =>
    json.encode(data.toJson());

class SuppressionPanierResponseModel {
  String sms;
  int statusCode;
  bool success;

  SuppressionPanierResponseModel({
    required this.sms,
    required this.statusCode,
    required this.success,
  });

  factory SuppressionPanierResponseModel.fromJson(Map<String, dynamic> json) =>
      SuppressionPanierResponseModel(
        sms: json["sms"] ?? json["message"] ?? '',  // ← FIXED: Handle both "sms" and "message" fields, with fallback to empty string
        statusCode: json["status_code"] ?? 200,
        success: json["success"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "sms": sms,
        "status_code": statusCode,
        "success": success,
      };
}
